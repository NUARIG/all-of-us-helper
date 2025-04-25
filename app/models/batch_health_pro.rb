require 'csv'
require 'study_tracker_api'
require 'health_pro_api'
class BatchHealthPro < ApplicationRecord
  has_paper_trail
  STATUS_PENDING = 'pending'
  STATUS_READY = 'ready'
  STATUS_EXPIRED = 'expired'
  STATUS_ERROR = 'error'
  STATUSES = [STATUS_PENDING, STATUS_READY, STATUS_EXPIRED, STATUS_ERROR]

  MATCH_STATUS_OPEN = 'open'
  MATCH_STATUS_CLOSED = 'closed'
  MATCH_STATUSES = [MATCH_STATUS_OPEN, MATCH_STATUS_CLOSED]
  BATCH_TYPE_FILE_UPLOAD = 'File Upload'
  BATCH_TYPE_HEALTH_PRO_API = 'Health Pro API'
  BATCH_TYPES = [BATCH_TYPE_FILE_UPLOAD, BATCH_TYPE_HEALTH_PRO_API]

  mount_uploader :health_pro_file, HealthProFileUploader

  has_many :health_pros
  validates_presence_of :health_pro_file, if: :file_upload?
  validates_size_of :health_pro_file, maximum: 10.megabytes, message: 'must be less than 10MB'

  after_destroy :remove_health_pro_file!
  after_initialize :set_defaults

  scope :by_status, ->(*statuses) do
    if statuses.any?
     where(status: statuses)
    end
  end

  scope :by_match_status, ->(match_status) do
    case match_status
      when BatchHealthPro::MATCH_STATUS_OPEN
        where('EXISTS (SELECT 1 FROM health_pros JOIN matches ON health_pros.id = matches.health_pro_id WHERE batch_health_pros.id = health_pros.batch_health_pro_id AND matches.status = ?)', Match::STATUS_PENDING)
      when BatchHealthPro::MATCH_STATUS_CLOSED
        where('NOT EXISTS (SELECT 1 FROM health_pros JOIN matches ON health_pros.id = matches.health_pro_id WHERE batch_health_pros.id = health_pros.batch_health_pro_id AND matches.status = ?)', Match::STATUS_PENDING)
      else
        where('1=1')
    end
  end

  def self.expire
    BatchHealthPro.by_status(BatchHealthPro::STATUS_READY).update_all(status: BatchHealthPro::STATUS_EXPIRED)
  end

  def pending?
    status == BatchHealthPro::STATUS_PENDING
  end

  def ready?
    status == BatchHealthPro::STATUS_READY
  end

  def import_api(options={})
    options = { update_previously_matched: true }.merge(options)
    begin
      health_pro_api = HealthProApi.new
      response = health_pro_api.participant_summary(options)

      # puts response[:response]
      Rails.logger.info '[HealthPro Import API] got response'
      if response[:response]['link'].present?
        link = response[:response]['link']
        if link && link.first['relation'] == 'next'
          url = link.first['url']
          token = url.partition('token=').last
        end
      end

      more = true
      batch_size = response[:response]['entry'].size
      while more
        Rails.logger.info '[HealthPro Import API] processing more entries'
        response[:response]['entry'].each do |health_pro_from_api|
          health_pro_from_api = health_pro_from_api['resource']
          row = {}
          BatchHealthPro.api_headers_map.each_pair do |k,v|
            row[v.to_sym] = health_pro_from_api.to_hash[k.to_s]
          end
          if health_pro_from_api.to_hash['withdrawalAuthored'].blank?  && !health_pro_from_api.to_hash['withdrawalTime'].blank?
            row[:withdrawal_date] = health_pro_from_api.to_hash['withdrawalTime']
          end
          Rails.logger.info '[HealthPro Import API] mapped API headers'
          convert_dates(row)
          Rails.logger.info '[HealthPro Import API] converted dates'
          health_pros.build(row)
          Rails.logger.info '[HealthPro Import API] built health_pros from row'
          health_pros.last.set_digital_health_fields
          Rails.logger.info '[HealthPro Import API] set digital health fields'
        end

        Rails.logger.info "[HealthPro Import API] renewing token? token: #{token} batch_size: #{batch_size}"
        if token && batch_size == 1000
          Rails.logger.info '[HealthPro Import API] renewing token?'
          participant_summary_options = { _token: token }
          response = health_pro_api.participant_summary(participant_summary_options)
          if response
            Rails.logger.info '[HealthPro Import API] got response'
            link = response[:response]['link']
            batch_size = response[:response]['entry'].size
            if link.present?
              Rails.logger.info '[HealthPro Import API] got link'
              url = link.first['url']
              tokenNew = url.partition('token=').last

              if token != tokenNew
                Rails.logger.info '[HealthPro Import API] tokens do not match, assigning new'
                token = tokenNew
              else
                Rails.logger.info '[HealthPro Import API] tokens match, nullifying'
                token = nil
              end
            end
          end
        else
          Rails.logger.info '[HealthPro Import API] no more'
          more = false
        end
      end

      save!
      Rails.logger.info '[HealthPro Import API] batch_health_pro saved'

      Rails.logger.info '[HealthPro Import API] processing health_pros'
      health_pros.where("((paired_organization = 'UNSET' OR paired_organization IN (?)) OR (paired_organization IN (?) AND (paired_site = 'UNSET' OR paired_site IN(?))))", [HealthPro::PAIRED_ORGANIZATION_NORTHWESTERN], [HealthPro::PAIRED_ORGANIZATION_NEAR_NORTH, HealthPro::PAIRED_ORGANIZATION_ILLINOIS_ERIE], HealthPro::PAIRED_SITES).each do |health_pro|
        health_pro.determine_matches
        Rails.logger.info '[HealthPro Import API] determined matches'

        if health_pro.matchable?
          # MGURLEY 11/15/2022 Commenting out.  We don't use this information.
          # Rails.logger.info '[HealthPro Import API] health_pro is matchable'
          # health_pro.determine_empi_matches
          Rails.logger.info '[HealthPro Import API] determined empi_matches'
          health_pro.determine_duplicates
          Rails.logger.info '[HealthPro Import API] determined duplicates'
        end

        health_pro.save!
        Rails.logger.info '[HealthPro Import API] saved'
        Rails.logger.info "[HealthPro Import API] update_previously_matched: #{options[:update_previously_matched]}"
        if options[:update_previously_matched]
          update_previously_matched_patient(health_pro, options)
          Rails.logger.info '[HealthPro Import API] updated previously matched patient'
        end
      end
      Rails.logger.info '[HealthPro Import API] done processing health_pros'

      self.status = BatchHealthPro::STATUS_READY
      save!
      Rails.logger.info "[HealthPro Import API] batch_health_pro status set to #{BatchHealthPro::STATUS_READY}"

    rescue Exception => e
      Rails.logger.info '[HealthPro Import API] Booch we have a problem!'
      ExceptionNotifier.notify_exception(e)
      set_status_to_error
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
      false
    end
  end

  def update_previously_matched_patient(health_pro, options)
    if health_pro.status == HealthPro::STATUS_PREVIOUSLY_MATCHED
      matched_pmi_patient = Patient.not_deleted.where(pmi_id: health_pro.pmi_id).first
      matched_pmi_patient.birth_date = Date.parse(health_pro.date_of_birth) if matched_pmi_patient.birth_date.blank?
      matched_pmi_patient.set_registration_status
      # matched_pmi_patient.gender = health_pro.sex if matched_pmi_patient.gender.blank? && health_pro.sex.present?
      matched_pmi_patient.gender = health_pro.sex_to_patient_gender if matched_pmi_patient.gender.blank?
      matched_pmi_patient.general_consent_status = health_pro.general_consent_status
      matched_pmi_patient.general_consent_date = health_pro.general_consent_date
      matched_pmi_patient.ehr_consent_status = health_pro.ehr_consent_status
      matched_pmi_patient.ehr_consent_date = health_pro.ehr_consent_date
      matched_pmi_patient.withdrawal_status = health_pro.withdrawal_status
      matched_pmi_patient.withdrawal_date = health_pro.withdrawal_date
      matched_pmi_patient.biospecimens_location = health_pro.biospecimens_location
      matched_pmi_patient.participant_status = health_pro.participant_status
      matched_pmi_patient.physical_measurements_completion_date = health_pro.physical_measurements_completion_date
      matched_pmi_patient.paired_site = health_pro.paired_site
      matched_pmi_patient.paired_organization = health_pro.paired_organization
      matched_pmi_patient.health_pro_email = health_pro.email
      matched_pmi_patient.health_pro_phone = health_pro.phone
      matched_pmi_patient.health_pro_login_phone = health_pro.login_phone
      matched_pmi_patient.genomic_consent_status = health_pro.consent_for_genomics_ror
      matched_pmi_patient.genomic_consent_status_date = health_pro.consent_for_genomics_ror_date
      matched_pmi_patient.questionnaire_on_cope_may = health_pro.questionnaire_on_cope_may
      matched_pmi_patient.questionnaire_on_cope_may_time = health_pro.questionnaire_on_cope_may_time
      matched_pmi_patient.questionnaire_on_cope_june = health_pro.questionnaire_on_cope_june
      matched_pmi_patient.questionnaire_on_cope_june_time = health_pro.questionnaire_on_cope_june_time
      matched_pmi_patient.questionnaire_on_cope_july = health_pro.questionnaire_on_cope_july
      matched_pmi_patient.questionnaire_on_cope_july_authored = health_pro.questionnaire_on_cope_july_authored
      matched_pmi_patient.core_participant_date = health_pro.core_participant_date
      matched_pmi_patient.deactivation_status = health_pro.deactivation_status
      matched_pmi_patient.deactivation_date = health_pro.deactivation_date
      matched_pmi_patient.required_ppi_surveys_complete = health_pro.required_ppi_surveys_complete
      matched_pmi_patient.completed_surveys = health_pro.completed_surveys
      matched_pmi_patient.basics_ppi_survey_complete = health_pro.basics_ppi_survey_complete
      matched_pmi_patient.basics_ppi_survey_completion_date = health_pro.basics_ppi_survey_completion_date
      matched_pmi_patient.health_ppi_survey_complete = health_pro.health_ppi_survey_complete
      matched_pmi_patient.health_ppi_survey_completion_date = health_pro.health_ppi_survey_completion_date
      matched_pmi_patient.lifestyle_ppi_survey_complete = health_pro.lifestyle_ppi_survey_complete
      matched_pmi_patient.lifestyle_ppi_survey_completion_date = health_pro.lifestyle_ppi_survey_completion_date
      matched_pmi_patient.hist_ppi_survey_complete = health_pro.hist_ppi_survey_complete
      matched_pmi_patient.hist_ppi_survey_completion_date = health_pro.hist_ppi_survey_completion_date
      matched_pmi_patient.meds_ppi_survey_complete = health_pro.meds_ppi_survey_complete
      matched_pmi_patient.meds_ppi_survey_completion_date = health_pro.meds_ppi_survey_completion_date
      matched_pmi_patient.family_ppi_survey_complete = health_pro.family_ppi_survey_complete
      matched_pmi_patient.family_ppi_survey_completion_date = health_pro.family_ppi_survey_completion_date
      matched_pmi_patient.access_ppi_survey_complete = health_pro.access_ppi_survey_complete
      matched_pmi_patient.access_ppi_survey_completion_date = health_pro.access_ppi_survey_completion_date
      matched_pmi_patient.date_of_first_primary_consent = health_pro.date_of_first_primary_consent
      matched_pmi_patient.date_of_first_ehr_consent = health_pro.date_of_first_ehr_consent

      if matched_pmi_patient.registered? #&& matched_pmi_patient.changed?
        puts 'here is the pmi_id to update'
        puts health_pro.pmi_id
        error = nil
        options = {}
        options[:proxy_user] = 'mjg994'
        study_tracker_api = StudyTrackerApi.new
        registraion_results = study_tracker_api.register(options, matched_pmi_patient)
        error = registraion_results[:error]
      end
      matched_pmi_patient.save!
    end
  end

  def import
    begin
      data = ''
      f = File.open(health_pro_file.current_path)
      f.each_line do |line|
        unless line.match(/^""\n/) || line.include?('Confidential Information') || line.include?('This file contains information that is sensitive and confidential. Do not distribute either the file or its contents.')
          data += line
        end
      end
      health_pros_from_file = CSV.new(data, headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

      if errors.empty?
        # BatchHealthPro.transaction do
          health_pros_from_file.each do |health_pro_from_file|
            row = {}
            BatchHealthPro.headers_map.each_pair do |k,v|
              row[v.to_sym] = health_pro_from_file.to_hash[k.to_s]
            end

            health_pros.build(row)
          end

          health_pros.each do |health_pro|
            health_pro.determine_matches

            if health_pro.matchable?
              health_pro.determine_empi_matches
              health_pro.determine_duplicates
            end

            health_pro.save!

            if health_pro.status == HealthPro::STATUS_PREVIOUSLY_MATCHED
              matched_pmi_patient = Patient.not_deleted.where(pmi_id: health_pro.pmi_id).first
              matched_pmi_patient.birth_date = Date.parse(health_pro.date_of_birth) if matched_pmi_patient.birth_date.blank?
              matched_pmi_patient.gender = health_pro.sex if matched_pmi_patient.gender.blank? && health_pro.sex.present?
              matched_pmi_patient.general_consent_status = health_pro.general_consent_status
              matched_pmi_patient.general_consent_date = health_pro.general_consent_date
              matched_pmi_patient.ehr_consent_status = health_pro.ehr_consent_status
              matched_pmi_patient.ehr_consent_date = health_pro.ehr_consent_date
              matched_pmi_patient.withdrawal_status = health_pro.withdrawal_status
              matched_pmi_patient.withdrawal_date = health_pro.withdrawal_date
              matched_pmi_patient.biospecimens_location = health_pro.biospecimens_location
              matched_pmi_patient.participant_status = health_pro.participant_status
              matched_pmi_patient.paired_site = health_pro.paired_site
              matched_pmi_patient.paired_organization = health_pro.paired_organization
              matched_pmi_patient.health_pro_email = health_pro.email
              # matched_pmi_patient.health_pro_login_phone = health_pro.login_phone
              matched_pmi_patient.set_registration_status
              matched_pmi_patient.physical_measurements_completion_date = health_pro.physical_measurements_completion_date
              #new stuff

              matched_pmi_patient.genomic_consent_status_date = health_pro.consent_for_genomics_ror_date
              matched_pmi_patient.genomic_consent_status = health_pro.consent_for_genomics_ror
              matched_pmi_patient.core_participant_date = health_pro.core_participant_date
              matched_pmi_patient.deactivation_status = health_pro.deactivation_status
              matched_pmi_patient.deactivation_date = health_pro.deactivation_date
              matched_pmi_patient.required_ppi_surveys_complete = health_pro.required_ppi_surveys_complete
              matched_pmi_patient.completed_surveys = health_pro.completed_surveys
              matched_pmi_patient.basics_ppi_survey_complete = health_pro.basics_ppi_survey_complete
              matched_pmi_patient.basics_ppi_survey_completion_date = health_pro.basics_ppi_survey_completion_date
              matched_pmi_patient.health_ppi_survey_complete = health_pro.health_ppi_survey_complete
              matched_pmi_patient.health_ppi_survey_completion_date = health_pro.health_ppi_survey_completion_date
              matched_pmi_patient.lifestyle_ppi_survey_complete = health_pro.lifestyle_ppi_survey_complete
              matched_pmi_patient.lifestyle_ppi_survey_completion_date = health_pro.lifestyle_ppi_survey_completion_date
              matched_pmi_patient.hist_ppi_survey_complete = health_pro.hist_ppi_survey_complete
              matched_pmi_patient.hist_ppi_survey_completion_date = health_pro.hist_ppi_survey_completion_date
              matched_pmi_patient.meds_ppi_survey_complete = health_pro.meds_ppi_survey_complete
              matched_pmi_patient.meds_ppi_survey_completion_date = health_pro.meds_ppi_survey_completion_date
              matched_pmi_patient.family_ppi_survey_complete = health_pro.family_ppi_survey_complete
              matched_pmi_patient.family_ppi_survey_completion_date = health_pro.family_ppi_survey_completion_date
              matched_pmi_patient.access_ppi_survey_complete = health_pro.access_ppi_survey_complete
              matched_pmi_patient.access_ppi_survey_completion_date = health_pro.access_ppi_survey_completion_date

              if matched_pmi_patient.registered? && matched_pmi_patient.changed?
                error = nil
                options = {}
                options[:proxy_user] = self.created_user
                study_tracker_api = StudyTrackerApi.new
                registraion_results = study_tracker_api.register(options, matched_pmi_patient)
                error = registraion_results[:error]
              end
              matched_pmi_patient.save!
            end
          # end
        end
        self.status = BatchHealthPro::STATUS_READY
        save!
      else
        false
      end
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      set_status_to_error
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
      false
    end
  end

  def set_status_to_error
    begin
      self.status = BatchHealthPro::STATUS_ERROR
      save!
    rescue Exception => e
    end
  end

  def self.api_headers_map
    {
      'participantId' => 'pmi_id',
      'biobankId' => 'biobank_id',
      'lastName' => 'last_name',
      'firstName' => 'first_name',
      'middleName' => 'middle_name',
      'dateOfBirth' => 'date_of_birth',
      'language' => 'language',
      'enrollmentStatus' => 'participant_status', # deprecated
      # Participant Status
      'consentForStudyEnrollment' => 'general_consent_status',
      'consentForStudyEnrollmentAuthored' => 'general_consent_date',
      'consentForElectronicHealthRecords' => 'ehr_consent_status',
      'consentForElectronicHealthRecordsAuthored' => 'ehr_consent_date',
      'consentForCABoR' => 'cabor_consent_status', # deprecated
      'consentForCABoRTimeAuthored' => 'cabor_consent_date', # deprecated
      'withdrawalStatus' => 'withdrawal_status',
      'withdrawalAuthored' => 'withdrawal_date',
      'suspensionStatus' => 'deactivation_status',
      'suspensionTime' => 'deactivation_date',
      'withdrawalReason' => 'withdrawal_reason',
      'streetAddress' => 'street_address',
      'streetAddress2' => 'street_address2',
      'city' => 'city',
      'state' => 'state',
      'zipCode' => 'zip',
      'email' => 'email',
      'phoneNumber' => 'phone',
      'ageRange' => 'age_range', # deprecated
      'sex' => 'sex',
      'genderIdentity' => 'gender_identity',
      'race' => 'race_ethnicity',
      'education' => 'education',
      'numCompletedBaselinePPIModules' => 'required_ppi_surveys_complete', # deprecated
      'numCompletedPPIModules' => 'completed_surveys', # deprecated
      'questionnaireOnTheBasics' => 'basics_ppi_survey_complete',
      'questionnaireOnTheBasicsAuthored' => 'basics_ppi_survey_completion_date',
      'questionnaireOnOverallHealth' => 'health_ppi_survey_complete',
      'questionnaireOnOverallHealthAuthored' => 'health_ppi_survey_completion_date',
      'questionnaireOnLifestyle' => 'lifestyle_ppi_survey_complete',
      'questionnaireOnLifestyleAuthored' => 'lifestyle_ppi_survey_completion_date',
      'questionnaireOnMedicalHistory' => 'hist_ppi_survey_complete', # deprecated
      'questionnaireOnMedicalHistoryAuthored' => 'hist_ppi_survey_completion_date', # deprecated
      'questionnaireOnFamilyHealth' => 'family_ppi_survey_complete', # deprecated
      'questionnaireOnFamilyHealthAuthored' => 'family_ppi_survey_completion_date', # deprecated
      'questionnaireOnHealthcareAccess' => 'access_ppi_survey_complete',
      'questionnaireOnHealthcareAccessAuthored' => 'access_ppi_survey_completion_date',
      # 'questionnaireOnMedications' => 'meds_ppi_survey_complete',
      # 'questionnaireOnMedicationsAuthored' => 'meds_ppi_survey_completion_date',
      'physicalMeasurementsStatus' => 'physical_measurements_status',
      'physicalMeasurementsFinalizedTime' => 'physical_measurements_completion_date',
      'site' => 'paired_site', # deprecated
      'organization' => 'paired_organization',
      #Paired Site
      #Paired Organization
      #'Physical Measurements Location' => 'physical_measurements_location',
      'physicalMeasurementsFinalizedSite' => 'physical_measurements_location',
      'samplesToIsolateDNA' => 'samples_for_dna_received',
      'numBaselineSamplesArrived' => 'biospecimens',
      'sampleStatus1SST8' => 'eight_ml_sst_collected',
      'sampleStatus1SST8Time' => 'eight_ml_sst_collection_date',
      'sampleStatus1PST8' => 'eight_ml_pst_collected',
      'sampleStatus1PST8Time' => 'eight_ml_pst_collection_date',
      'sampleStatus1HEP4' => 'four_ml_na_hep_collected',
      'sampleStatus1HEP4Time' => 'four_ml_na_hep_collection_date',
      'sampleStatus1ED02' => 'two_ml_edta_collected',
      'sampleStatus1ED02Time' => 'two_ml_edta_collected_date',
      'sampleStatus1ED04' => 'four_ml_edta_collected',
      'sampleStatus1ED04Time' => 'four_ml_edta_collection_date',
      'sampleStatus1ED10' => 'first_10_ml_edta_collected',
      'sampleStatus1ED10Time' => 'first_10_ml_edta_collection_date',
      'sampleStatus2ED10' => 'second_10_ml_edta_collected',
      'sampleStatus2ED10Time' => 'second_10_ml_edta_collection_date',
      'sampleStatus1CFD9' => 'cell_free_dna_collected',
      'sampleStatus1CFD9Time' => 'cell_free_dna_collected_date',
      'sampleStatus1PXR2' => 'paxgene_rna_collected',
      'sampleStatus1PXR2Time' => 'paxgene_rna_collected_date',
      'sampleStatus1UR10' => 'urine_10_ml_collected',
      'sampleStatus1UR10Time' => 'urine_10_ml_collection_date',
      'sampleStatus1UR90' => 'urine_90_ml_collected',
      'sampleStatus1UR90Time' => 'urine_90_ml_collection_date',
      'sampleStatus1SAL' => 'saliva_collected',
      'sampleStatus1SALTime' => 'saliva_collection_date',
      # 'Biospecimens Location' => 'biospecimens_location'
      'biospecimenSourceSite' => 'biospecimens_location',
      'primaryLanguage' => 'language_of_general_consent',
      'consentForDvElectronicHealthRecordsSharing' => 'dv_only_ehr_sharing_status', # deprecated
      # 'DV-only EHR Sharing Date' => 'dv_only_ehr_sharing_date',
      'loginPhoneNumber' => 'login_phone', #deprecated
      #new
      'patientStatus' => 'patient_status', # deprecated
      'enrollmentStatusCoreStoredSampleTime' => 'core_participant_date', #deprecated
      'participantOrigin' => 'participant_origination', # deprecated
      'consentForGenomicsROR' => 'consent_for_genomics_ror', # deprecated
      'consentForGenomicsRORAuthored' => 'consent_for_genomics_ror_date', # deprecated
      'questionnaireOnCopeMay' => 'questionnaire_on_cope_may', # deprecated
      'questionnaireOnCopeMayTime' => 'questionnaire_on_cope_may_time', # deprecated
      'questionnaireOnCopeJune' => 'questionnaire_on_cope_june', # deprecated
      'questionnaireOnCopeJuneTime' => 'questionnaire_on_cope_june_time', # deprecated
      'questionnaireOnCopeJuly' => 'questionnaire_on_cope_july', # deprecated
      'questionnaireOnCopeJulyAuthored' => 'questionnaire_on_cope_july_authored', # deprecated

      #new moomin
      'consentCohort' => 'consent_cohort', # deprecated
      'questionnaireOnDnaProgram' => 'program_update', # deprecated
      'questionnaireOnDnaProgramAuthored' => 'date_of_program_update', # deprecated
      'ehrConsentExpireStatus' => 'ehr_expiration_status', # deprecated
      'ehrconsentExpireAuthored' => 'date_of_ehr_expiration', # deprecated
      'consentForStudyEnrollmentFirstYesAuthored' => 'date_of_first_primary_consent', # deprecated
      'consentForElectronicHealthRecordsFirstYesAuthored' => 'date_of_first_ehr_consent', # deprecated
      'retentionEligibleStatus' => 'retention_eligible',
      'retentionEligibleTime' => 'date_of_retention_eligibility',
      'deceasedStatus' => 'deceased',
      'dateOfDeath' => 'date_of_death',
      'deceasedAuthored' => 'date_of_approval',
      'questionnaireOnCopeNov' => 'cope_nov_ppi_survey_complete', # deprecated
      'questionnaireOnCopeNovAuthored' => 'cope_nov_ppi_survey_completion_date', # deprecated
      'retentionType' => 'retention_status',
      'ehrStatus' => 'ehr_data_transfer',
      'latestEhrReceiptTime' => 'most_recent_ehr_receipt',
      'sample1SAL2CollectionMethod' => 'saliva_collection',
      'questionnaireOnCopeDec' => 'cope_dec_ppi_survey_complete', # deprecated
      'questionnaireOnCopeDecAuthored' => 'cope_dec_ppi_survey_completion_date', # deprecated
      #new mommin 2
      'questionnaireOnCopeFeb' => 'cope_feb_ppi_survey_complete',
      'questionnaireOnCopeFebAuthored' => 'cope_feb_ppi_survey_completion_date',
      'enrollmentStatusCoreMinusPMTime' => 'core_participant_minus_pm_date', # deprecated
      'questionnaireOnCopeVaccineMinute1' => 'summer_minute_ppi_survey_complete', # deprecated
      'questionnaireOnCopeVaccineMinute1Authored' => 'summer_minute_ppi_survey_completion_date', # deprecated
      'questionnaireOnCopeVaccineMinute2' => 'fall_minute_ppi_survey_complete', # deprecated
      'questionnaireOnCopeVaccineMinute2Authored' => 'fall_minute_ppi_survey_completion_date', # deprecated
      'digitalHealthSharingStatus' => 'digital_health_consent',
      'questionnaireOnPersonalAndFamilyHealthHistory' => 'personal_and_family_hx_ppi_survey_complete',
      'questionnaireOnPersonalAndFamilyHealthHistoryAuthored' => 'personal_and_family_hx_ppi_survey_completion_date',
      'questionnaireOnSocialDeterminantsOfHealth' => 'sdoh_ppi_survey_complete',
      'questionnaireOnSocialDeterminantsOfHealthAuthored' => 'sdoh_ppi_survey_completion_date',
      'questionnaireOnCopeVaccineMinute3' => 'winter_minute_ppi_survey_complete', # deprecated
      'questionnaireOnCopeVaccineMinute3Authored' => 'winter_minute_ppi_survey_completion_date', # deprecated
      'enrollmentSite' => 'enrollment_site', # deprecated
      'questionnaireOnCopeVaccineMinute4' => 'new_year_minute_ppi_survey_complete', # deprecated
      'questionnaireOnCopeVaccineMinute4Authored' => 'new_year_minute_ppi_survey_completion_date', # deprecated

      'physicalMeasurementsCollectType' => 'physical_measurements_collect_type',
      'onsiteIdVerificationTime' => 'onsite_id_verification_time',
      'participantIncentives' => 'participant_incentives',
      'selfReportedPhysicalMeasurementsStatus' => 'self_reported_physical_measurements_status',
      'selfReportedPhysicalMeasurementsAuthored' => 'self_reported_physical_measurements_authored',
      'clinicPhysicalMeasurementsFinalizedTime' => 'clinic_physical_measurements_finalized_time',
      'clinicPhysicalMeasurementsFinalizedSite' => 'clinic_physical_measurements_finalized_site',
      'clinicPhysicalMeasurementsTime' => 'clinic_physical_measurements_time',
      'clinicPhysicalMeasurementsCreatedSite' => 'clinic_physical_measurements_created_site',
      'reconsentForStudyEnrollmentAuthored' => 'reconsent_for_study_enrollment_authored', # deprecated
      'reconsentForElectronicHealthRecordsAuthored' => 'reconsent_for_electronic_health_records_authored', # deprecated
      'questionnaireOnLifeFunctioning' => 'questionnaire_on_life_functioning',
      'questionnaireOnLifeFunctioningAuthored' => 'questionnaire_on_life_functioning_authored',

      'questionnaireOnBehavioralHealthAndPersonality' => 'questionnaire_on_behaviorial_health_and_personality',
      'questionnaireOnEmotionalHealthHistoryAndWellBeing' => 'questionnaire_on_emotional_health_history_and_well_being',

      'questionnaireOnBehavioralHealthAndPersonalityAuthored' => 'questionnaire_on_behaviorial_health_and_personality_authored',
      'questionnaireOnEmotionalHealthHistoryAndWellBeingAuthored' => 'questionnaire_on_emotional_health_history_and_well_being_author',
      'questionnaireOnEnvironmentalExposures' => 'questionnaire_on_environmental_exposures',
      'questionnaireOnEnvironmentalExposuresAuthored' => 'questionnaire_on_environmental_exposures_authored'
    }
  end

  def self.headers_map
    {
      'PMI ID' => 'pmi_id',
      'Biobank ID' => 'biobank_id',
      'Last Name' => 'last_name',
      'First Name' => 'first_name',
      'Date of Birth' => 'date_of_birth',
      'Language' => 'language',
      'Participant Status' => 'participant_status',
      # Participant Status
      'General Consent Status' => 'general_consent_status',
      'General Consent Date' => 'general_consent_date',
      'EHR Consent Status' => 'ehr_consent_status',
      'EHR Consent Date' => 'ehr_consent_date',
      'CABoR Consent Status' => 'cabor_consent_status',
      'CABoR Consent Date' => 'cabor_consent_date',
      'Withdrawal Status' => 'withdrawal_status',
      'Withdrawal Date' => 'withdrawal_date',
      'Street Address' => 'street_address',
      'City' => 'city',
      'State' => 'state',
      'ZIP' => 'zip',
      'Email' => 'email',
      'Phone' => 'phone',
      'Sex' => 'sex',
      'Gender Identity' => 'gender_identity',
      'Race/Ethnicity' => 'race_ethnicity',
      'Education' => 'education',
      'Required PPI Surveys Complete' => 'required_ppi_surveys_complete',
      'Completed Surveys' => 'completed_surveys',
      'Basics PPI Survey Complete' => 'basics_ppi_survey_complete',
      'Basics PPI Survey Completion Date' => 'basics_ppi_survey_completion_date',
      'Health PPI Survey Complete' => 'health_ppi_survey_complete',
      'Health PPI Survey Completion Date' => 'health_ppi_survey_completion_date',
      'Lifestyle PPI Survey Complete' => 'lifestyle_ppi_survey_complete',
      'Lifestyle PPI Survey Completion Date' => 'lifestyle_ppi_survey_completion_date',
      'Hist PPI Survey Complete' => 'hist_ppi_survey_complete',
      'Hist PPI Survey Completion Date' => 'hist_ppi_survey_completion_date',
      'Meds PPI Survey Complete' => 'meds_ppi_survey_complete',
      'Meds PPI Survey Completion Date' => 'meds_ppi_survey_completion_date',
      'Family PPI Survey Complete' => 'family_ppi_survey_complete',
      'Family PPI Survey Completion Date' => 'family_ppi_survey_completion_date',
      'Access PPI Survey Complete' => 'access_ppi_survey_complete',
      'Access PPI Survey Completion Date' => 'access_ppi_survey_completion_date',
      'Physical Measurements Status' => 'physical_measurements_status',
      'Physical Measurements Completion Date' => 'physical_measurements_completion_date',
      'Paired Site' => 'paired_site',
      'Paired Organization' => 'paired_organization',
      #Paired Site
      #Paired Organization
      #'Physical Measurements Location' => 'physical_measurements_location',
      'Physical Measurements Site' => 'physical_measurements_location',
      'Samples for DNA Received' => 'samples_for_dna_received',
      'Biospecimens' => 'biospecimens',
      '8 mL SST Collected' => 'eight_ml_sst_collected',
      '8 mL SST Collection Date' => 'eight_ml_sst_collection_date',
      '8 mL PST Collected' => 'eight_ml_pst_collected',
      '8 mL PST Collection Date' => 'eight_ml_pst_collection_date',
      '4 mL Na-Hep Collected' => 'four_ml_na_hep_collected',
      '4 mL Na-Hep Collection Date' => 'four_ml_na_hep_collection_date',
      '2 mL EDTA Collected' => 'two_ml_edta_collected',
      '2 mL EDTA Collection Date' => 'two_ml_edta_collected_date',
      '4 mL EDTA Collected' => 'four_ml_edta_collected',
      '4 mL EDTA Collection Date' => 'four_ml_edta_collection_date',
      '1st 10 mL EDTA Collected' => 'first_10_ml_edta_collected',
      '1st 10 mL EDTA Collection Date' => 'first_10_ml_edta_collection_date',
      '2nd 10 mL EDTA Collected' => 'second_10_ml_edta_collected',
      '2nd 10 mL EDTA Collection Date' => 'second_10_ml_edta_collection_date',
      'Urine 10 mL Collected' => 'urine_10_ml_collected',
      'Urine 10 mL Collection Date' => 'urine_10_ml_collection_date',
      'Urine 90 mL Collected' => 'urine_90_ml_collected',
      'Urine 90 mL Collection Date' => 'urine_90_ml_collection_date',
      'Cell-Free DNA Collected' => 'cell_free_dna_collected',
      'Cell-Free DNA Collection Date' => 'cell_free_dna_collected_date',
      'Paxgene RNA Collected' => 'paxgene_rna_collected',
      'Paxgene RNA Collection Date' => 'paxgene_rna_collected_date',
      'Saliva Collected' => 'saliva_collected',
      'Saliva Collection Date' => 'saliva_collection_date',
      # 'Biospecimens Location' => 'biospecimens_location'
      'Biospecimens Site' => 'biospecimens_location',
      'Withdrawal Reason' => 'withdrawal_reason',
      'Language of General Consent' => 'language_of_general_consent',
      'DV-only EHR Sharing Status' => 'dv_only_ehr_sharing_status',
      'DV-only EHR Sharing Date' => 'dv_only_ehr_sharing_date',
      'Login Phone' => 'login_phone',
      'Street Address2' => 'street_address2',
    }
  end

  def file_upload?
    self.batch_type == BatchHealthPro::BATCH_TYPE_FILE_UPLOAD
  end

  private
    def set_defaults
      if self.new_record?
        self.status = BatchHealthPro::STATUS_PENDING
        self.batch_type = BatchHealthPro::BATCH_TYPE_FILE_UPLOAD
      end
    end

    def convert_dates(row)
      ['general_consent_date', 'ehr_consent_date', 'withdrawal_date', 'physical_measurements_completion_date', 'genomic_consent_status_date', 'core_participant_date', 'deactivation_date', 'basics_ppi_survey_completion_date', 'health_ppi_survey_completion_date', 'lifestyle_ppi_survey_completion_date', 'hist_ppi_survey_completion_date', 'meds_ppi_survey_completion_date',  'family_ppi_survey_completion_date', 'access_ppi_survey_completion_date', 'questionnaire_on_cope_may_time', 'questionnaire_on_cope_june_time', 'questionnaire_on_cope_july_authored', 'date_of_first_primary_consent', 'date_of_first_ehr_consent', 'questionnaire_on_behaviorial_health_and_personality_authored', 'questionnaire_on_emotional_health_history_and_well_being_author', 'questionnaire_on_environmental_exposures_authored'].each do |column|
        convert_date(row, column)
      end
    end

    def convert_date(row, column)
      if row[column.to_sym].present?
        row[column.to_sym] = Time.parse("#{row[column.to_sym]} UTC").in_time_zone('Central Time (US & Canada)').iso8601
      end
    end
end
