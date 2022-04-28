require 'redcap_api'
require 'csv'
namespace :redcap do
  desc 'Assign invitation codes'
  task(assign_invitation_codes: :environment) do  |t, args|
    begin
      setting = Setting.first
      if setting.auto_assign_invitation_codes
        api_token = ApiToken.where(api_token_type: ApiToken::API_TOKEN_TYPE_REDCAP).first
        raise 'No RedCAP API token is setup.' if api_token.blank?
        redcap_api = RedcapApi.new(api_token.token)

        pending_invitation_code_assignments = redcap_api.pending_invitation_code_assignments
        if pending_invitation_code_assignments[:error].blank? && pending_invitation_code_assignments[:response].any?
          pending_invitation_code_assignments[:response].each do |pending_invitation_code_assignment|
            record_id = pending_invitation_code_assignment['record_id']
            redcap_patient = redcap_api.patient(record_id)
            if redcap_patient[:error].blank? && redcap_patient[:response].present?
              patient = Patient.create_or_update!(redcap_patient[:response].slice('record_id', 'first_name', 'last_name', 'email', 'phone_1'))
              patient.assign_invitation_code(redcap_api)
              raise "Error assigning invitation code to record_id #{record_id}." if patient.errors.any?
            end
          end
        end
      end
    rescue => error
      handle_error(t, error)
    end
  end

  desc "Synch patients."
  task(synch_patients: :environment) do  |t, args|
    redcap_api = RedcapApi.initialize_redcap_api
    patients = redcap_api.patients
    if patients[:error].blank? && patients[:response].any?
      patients[:response].each do |patient|
        patient = patient.slice('record_id', 'first_name', 'last_name', 'email', 'phone_1')
        patient['first_name'].strip!
        patient['last_name'].strip!
        @patient = Patient.where(record_id: patient['record_id']).first
        if @patient.blank?
          if patient['first_name'].present? && patient['last_name'].present?
            @patient = Patient.create!(patient)
          end
        else
          if @patient.nmhc_mrn.blank?
            @patient.first_name = patient['first_name']
            @patient.last_name = patient['last_name']
          end
          @patient.email = patient['email']
          @patient.phone_1 = patient['phone_1']
          @patient.save!
        end
      end
    end
  end

  desc "Synch deleted patients."
  task(synch_deleted_patients: :environment) do  |t, args|
    begin
      redcap_api = RedcapApi.initialize_redcap_api
      patients = redcap_api.patients

      record_ids = patients[:response].map { |patient| patient['record_id']  }
      Patient.where('record_id != pmi_id OR pmi_id IS NULL').each do |patient|
        puts patient.record_id
        if !record_ids.include?(patient.record_id)
          patient.soft_delete!
        end
      end
    rescue => error
      handle_error(t, error)
    end
  end

  desc "Synch patients to REDCap"
  task(synch_patients_to_redcap: :environment) do  |t, args|
    begin
      redcap_api = RedcapApi.initialize_redcap_api
      Patient.not_deleted.where("pmi_id != record_id AND pmi_id IS NOT NULL AND pmi_id != ''").each do |patient|
        puts "Here is the pmi_id #{patient.pmi_id}"
        sleep(0.25)
        redcap_patient = redcap_api.update_patient(patient.record_id, patient.pmi_id, patient.general_consent_status, patient.general_consent_date, patient.ehr_consent_status, patient.ehr_consent_date, patient.withdrawal_status, patient.withdrawal_date, patient.participant_status, patient.physical_measurements_completion_date, patient.paired_site, patient.paired_organization, patient.health_pro_email, patient.health_pro_phone, patient.health_pro_login_phone, patient.genomic_consent_status, patient.genomic_consent_status_date, patient.core_participant_date, patient.deactivation_status, patient.deactivation_date, patient.required_ppi_surveys_complete, patient.completed_surveys, patient.basics_ppi_survey_complete, patient.basics_ppi_survey_completion_date, patient.health_ppi_survey_complete, patient.health_ppi_survey_completion_date, patient.lifestyle_ppi_survey_complete, patient.lifestyle_ppi_survey_completion_date, patient.access_ppi_survey_complete, patient.access_ppi_survey_completion_date, patient.questionnaire_on_cope_may, patient.questionnaire_on_cope_may_time, patient.questionnaire_on_cope_june, patient.questionnaire_on_cope_june_time, patient.questionnaire_on_cope_july, patient.questionnaire_on_cope_july_authored, patient.date_of_first_primary_consent, patient.date_of_first_ehr_consent, patient.health_pro_address1, patient.health_pro_address2, patient.health_pro_city, patient.health_pro_state, patient.health_pro_zip, patient.wq_program_update_status, patient.wq_program_update_date, patient.deceased, patient.cope_feb_ppi_survey_complete_y, patient.cope_feb_ppi_survey_completion_date_d, patient.core_participant_minus_pm_date_d, patient.summer_minute_ppi_survey_complete_y, patient.summer_minute_ppi_survey_completion_date_d, patient.fall_minute_ppi_survey_complete_y, patient.fall_minute_ppi_survey_completion_date_d, patient.personal_and_family_hx_ppi_survey_complete_y, patient.personal_and_family_hx_ppi_survey_completion_date_d, patient.sdoh_ppi_survey_complete_y, patient.sdoh_ppi_survey_completion_date_d, patient.winter_minute_ppi_survey_complete_y, patient.winter_minute_ppi_survey_completion_date_d, patient.digital_health_status_fitbit_complete_y, patient.digital_health_status_fitbit_completion_date_d, patient.digital_health_status_apple_health_kit_complete_y, patient.digital_health_status_apple_health_kit_completion_date_d, patient.digital_health_status_apple_health_ehr_complete_y, patient.digital_health_status_apple_health_ehr_completion_date_d, patient.hist_ppi_survey_complete, patient.hist_ppi_survey_completion_date, patient.family_ppi_survey_complete, patient.family_ppi_survey_completion_date)
      end
    rescue => error
      handle_error(t, error)
    end
  end

  # RAILS_ENV=staging bundle exec rake redcap:synch_one_patient_to_redcap["?"]
  desc "Synch patients to REDCap"
  task :synch_one_patient_to_redcap, [:record_id] => [:environment] do |t, args|
    begin
      redcap_api = RedcapApi.initialize_redcap_api
      Patient.not_deleted.where("pmi_id != record_id AND pmi_id IS NOT NULL AND pmi_id != '' AND record_id = ?", args[:record_id]).each do |patient|
        puts "Here is the pmi_id #{patient.pmi_id}"
        sleep(0.25)
        redcap_patient = redcap_api.update_patient(patient.record_id, patient.pmi_id, patient.general_consent_status, patient.general_consent_date, patient.ehr_consent_status, patient.ehr_consent_date, patient.withdrawal_status, patient.withdrawal_date, patient.participant_status, patient.physical_measurements_completion_date, patient.paired_site, patient.paired_organization, patient.health_pro_email, patient.health_pro_phone, patient.health_pro_login_phone, patient.genomic_consent_status, patient.genomic_consent_status_date, patient.core_participant_date, patient.deactivation_status, patient.deactivation_date, patient.required_ppi_surveys_complete, patient.completed_surveys, patient.basics_ppi_survey_complete, patient.basics_ppi_survey_completion_date, patient.health_ppi_survey_complete, patient.health_ppi_survey_completion_date, patient.lifestyle_ppi_survey_complete, patient.lifestyle_ppi_survey_completion_date, patient.access_ppi_survey_complete, patient.access_ppi_survey_completion_date, patient.questionnaire_on_cope_may, patient.questionnaire_on_cope_may_time, patient.questionnaire_on_cope_june, patient.questionnaire_on_cope_june_time, patient.questionnaire_on_cope_july, patient.questionnaire_on_cope_july_authored, patient.date_of_first_primary_consent, patient.date_of_first_ehr_consent, patient.health_pro_address1, patient.health_pro_address2, patient.health_pro_city, patient.health_pro_state, patient.health_pro_zip, patient.wq_program_update_status, patient.wq_program_update_date, patient.deceased, patient.cope_feb_ppi_survey_complete_y, patient.cope_feb_ppi_survey_completion_date_d, patient.core_participant_minus_pm_date_d, patient.summer_minute_ppi_survey_complete_y, patient.summer_minute_ppi_survey_completion_date_d, patient.fall_minute_ppi_survey_complete_y, patient.fall_minute_ppi_survey_completion_date_d, patient.personal_and_family_hx_ppi_survey_complete_y, patient.personal_and_family_hx_ppi_survey_completion_date_d, patient.sdoh_ppi_survey_complete_y, patient.sdoh_ppi_survey_completion_date_d, patient.winter_minute_ppi_survey_complete_y, patient.winter_minute_ppi_survey_completion_date_d, patient.digital_health_status_fitbit_complete_y, patient.digital_health_status_fitbit_completion_date_d, patient.digital_health_status_apple_health_kit_complete_y, patient.digital_health_status_apple_health_kit_completion_date_d, patient.digital_health_status_apple_health_ehr_complete_y, patient.digital_health_status_apple_health_ehr_completion_date_d, patient.hist_ppi_survey_complete, patient.hist_ppi_survey_completion_date, patient.family_ppi_survey_complete, patient.family_ppi_survey_completion_date)
      end
    rescue => error
      handle_error(t, error)
    end
  end

  # RAILS_ENV=staging bundle exec rake redcap:rollback_accepted_match["?"]
  desc "Rollback accepted match for record_id"
  task :rollback_accepted_match, [:record_id] => [:environment] do |t, args|
    puts args[:record_id]
    patient = Patient.where(record_id: args[:record_id]).first
    matches = patient.matches.where(status: Match::STATUS_ACCEPTED)
    matches.each do |match|
      match.destroy
    end
    patient.pmi_id = nil
    patient.birth_date = nil
    patient.general_consent_status = nil
    patient.general_consent_date = nil
    patient.ehr_consent_status = nil
    patient.ehr_consent_date = nil
    patient.withdrawal_status = nil
    patient.withdrawal_date = nil
    patient.biospecimens_location = nil
    patient.participant_status = nil
    patient.paired_site = nil
    patient.paired_organization = nil
    patient.physical_measurements_completion_date = nil
    patient.registration_status = Patient::REGISTRATION_STATUS_UNMATCHED
    patient.nmhc_mrn = nil
    patient.save!

    redcap_api = RedcapApi.initialize_redcap_api
    redcap_patient = redcap_api.update_patient(patient.record_id, patient.pmi_id, patient.general_consent_status, patient.general_consent_date, patient.ehr_consent_status, patient.ehr_consent_date, patient.withdrawal_status, patient.withdrawal_date, patient.participant_status, patient.physical_measurements_completion_date, patient.paired_site, patient.paired_organization, patient.health_pro_email, patient.health_pro_phone, patient.health_pro_login_phone, patient.genomic_consent_status, patient.genomic_consent_status_date, patient.core_participant_date, patient.deactivation_status, patient.deactivation_date, patient.required_ppi_surveys_complete, patient.completed_surveys, patient.basics_ppi_survey_complete, patient.basics_ppi_survey_completion_date, patient.health_ppi_survey_complete, patient.health_ppi_survey_completion_date, patient.lifestyle_ppi_survey_complete, patient.lifestyle_ppi_survey_completion_date, patient.access_ppi_survey_complete, patient.access_ppi_survey_completion_date, patient.questionnaire_on_cope_may, patient.questionnaire_on_cope_may_time, patient.questionnaire_on_cope_june, patient.questionnaire_on_cope_june_time, patient.questionnaire_on_cope_july, patient.questionnaire_on_cope_july_authored, patient.date_of_first_primary_consent, patient.date_of_first_ehr_consent, patient.health_pro_address1, patient.health_pro_address2, patient.health_pro_city, patient.health_pro_state, patient.health_pro_zip, patient.wq_program_update_status, patient.wq_program_update_date, patient.deceased, patient.cope_feb_ppi_survey_complete_y, patient.cope_feb_ppi_survey_completion_date_d, patient.core_participant_minus_pm_date_d, patient.summer_minute_ppi_survey_complete_y, patient.summer_minute_ppi_survey_completion_date_d, patient.fall_minute_ppi_survey_complete_y, patient.fall_minute_ppi_survey_completion_date_d, patient.personal_and_family_hx_ppi_survey_complete_y, patient.personal_and_family_hx_ppi_survey_completion_date_d, patient.sdoh_ppi_survey_complete_y, patient.sdoh_ppi_survey_completion_date_d, patient.winter_minute_ppi_survey_complete_y, patient.winter_minute_ppi_survey_completion_date_d, patient.digital_health_status_fitbit_complete_y, patient.digital_health_status_fitbit_completion_date_d, patient.digital_health_status_apple_health_kit_complete_y, patient.digital_health_status_apple_health_kit_completion_date_d, patient.digital_health_status_apple_health_ehr_complete_y, patient.digital_health_status_apple_health_ehr_completion_date_d, patient.hist_ppi_survey_complete, patient.hist_ppi_survey_completion_date, patient.family_ppi_survey_complete, patient.family_ppi_survey_completion_date)
  end

  # scp -r deploy@vfsmnubicapps01.fsm.northwestern.edu:/var/www/apps/all-of-us-helper/releases/20190422170923/lib/setup/mrn_review.csv ~/hold/mrn_review.csv
  desc "Create MRN review"
  task(create_mrn_review: :environment) do  |t, args|
    batch_health_pro_id = BatchHealthPro.maximum(:id)
    patients = []
    Patient.where(registration_status:[Patient::REGISTRATION_STATUS_MATCHED, Patient::REGISTRATION_STATUS_READY]).all.each do |patient|
      p = {}
      p[:patient] = patient
      puts patient.pmi_id
      health_pro = HealthPro.where(batch_health_pro_id: batch_health_pro_id, pmi_id: patient.pmi_id).first
      p[:health_pro] = health_pro
      empi_patients = determine_empi_matches(patient, health_pro)
      p[:empi_patients] = empi_patients
      patients << p
    end

    patient_keys = Patient.first.attributes.keys - ['id', 'created_at', 'updated_at', 'registration_status', 'general_consent_status', 'general_consent_date', 'ehr_consent_status', 'ehr_consent_date', 'withdrawal_status', 'withdrawal_date', 'biospecimens_location', 'uuid', 'participant_status', 'deleted_at', 'physical_measurements_completion_date', 'paired_site', 'paired_organization']
    empi_keys = ['first_name', 'last_name', 'birth_date', 'gender', 'ethnicity', 'races', 'address_line1', 'city', 'state', 'zip', 'nmhc_mrn', 'nmh_mrn', 'nmff_mrn', 'lfh_mrn', 'address']
    empi_keys_namespaced = empi_keys.dup
    empi_keys_namespaced = empi_keys_namespaced.map{ |empi_key|  "empi_#{empi_key}"}
    health_pro_keys = ['health_pro_address']

    headers = patient_keys.concat(health_pro_keys)
    headers = patient_keys.concat(empi_keys_namespaced)
    row_header = CSV::Row.new(headers, headers, true)
    row_template = CSV::Row.new(headers, [], false)
    CSV.open('lib/setup/mrn_review.csv', "wb") do |csv|
      csv << row_header
      patients.each do |patient|
        patient[:empi_patients].each do |empi_patient|
          row = row_template.dup
          patient_keys.each do |key|
            row[key] = patient[:patient][key]
          end

          row['health_pro_address'] = patient[:health_pro].address

          empi_keys_namespaced.each do |key|
            row[key] = empi_patient[key.gsub('empi_','')]
          end
          csv << row
        end
      end
    end
  end

  desc "Migrate First Generation REDCap"
  task(migrate_first_generation: :environment) do  |t, args|
    patients_from_file = CSV.new(File.open('lib/setup/data/Import_5.20.20.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    redcap_api = RedcapApi.initialize_redcap_api
    patients_from_file.each do |patient_from_file|
      puts patient_from_file['record_id']
      puts patient_from_file['FIRSTGEN_record_id']
      puts patient_from_file['first_name']
      puts patient_from_file['last_name']
      puts patient_from_file['referralsource']
      puts patient_from_file['site_preference___1']
      puts patient_from_file['PMI_ID']
      patient = Patient.where(pmi_id: patient_from_file['PMI_ID']).first
      if !patient_from_file['record_id'].present?
        if patient.present? && patient.pmi_id == patient.record_id
          puts 'We found a match.'
          puts patient.record_id
          puts patient.pmi_id
          redcap_patient = redcap_api.create_patient_minnimum(patient_from_file['first_name'], patient_from_file['last_name'], patient_from_file['PMI_ID'], patient_from_file['referralsource'], patient_from_file['site_preference___1'], patient_from_file['FIRSTGEN_record_id'], patient.cope_feb_ppi_survey_complete_y, patient.cope_feb_ppi_survey_completion_date_d, patient.core_participant_minus_pm_date_d, patient.summer_minute_ppi_survey_complete_y, patient.summer_minute_ppi_survey_completion_date_d, patient.fall_minute_ppi_survey_complete_y, patient.fall_minute_ppi_survey_completion_date_d, patient.personal_and_family_hx_ppi_survey_complete_y, patient.personal_and_family_hx_ppi_survey_completion_date_d, patient.sdoh_ppi_survey_complete_y, patient.sdoh_ppi_survey_completion_date_d, patient.winter_minute_ppi_survey_complete_y, patient.winter_minute_ppi_survey_completion_date_d, patient.digital_health_status_fitbit_complete_y, patient.digital_health_status_fitbit_completion_date_d, patient.digital_health_status_apple_health_kit_complete_y, patient.digital_health_status_apple_health_kit_completion_date_d, patient.digital_health_status_apple_health_ehr_complete_y, patient.digital_health_status_apple_health_ehr_completion_date_d, patient.hist_ppi_survey_complete, patient.hist_ppi_survey_completion_date, patient.family_ppi_survey_complete, patient.family_ppi_survey_completion_date)
          record_id = redcap_patient[:response]
          patient.record_id = record_id
          patient.save!
        elsif patient.present? && patient.pmi_id != patient.record_id
          puts 'No match but with a record_id!'
          puts patient_from_file['PMI_ID']
        else
          puts 'No match!'
          puts patient_from_file['PMI_ID']
        end
      end
    end
  end
end

def handle_error(t, error)
  puts error.class
  puts error.message
  puts error.backtrace.join("\n")

  Rails.logger.info(error.class)
  Rails.logger.info(error.message)
  Rails.logger.info(error.backtrace.join("\n"))
  ExceptionNotifier.notify_exception(error)
end

def determine_empi_matches(patient, health_pro)
  empi_patients = []
  if health_pro.present?
    empi_params = {}
    error = nil
    study_tracker_api = StudyTrackerApi.new
    empi_params[:proxy_user] = 'mjg994'
    empi_params[:first_name] = patient.first_name
    empi_params[:last_name] = patient.last_name
    empi_params[:birth_date] = patient.birth_date
    empi_params[:address] = health_pro.address
    empi_params[:gender] = health_pro.sex_to_patient_gender
    empi_results = study_tracker_api.empi_lookup(empi_params)
    if empi_results[:error].present? || empi_results[:response]['error'].present?
    else
      empi_results[:response]['patients'].each do |empi_patient|
        empi_race_matches = []
        empi_patient['races'].each do |empi_race|
          race = Race.where(name: empi_race).first
        end
        empi_patient['address'] = format_address(empi_patient)
        # puts empi_patient['first_name']
        # puts empi_patient['last_name']
        # puts empi_patient['birth_date']
        # puts empi_patient['gender']
        # puts format_address(empi_patient)
        # puts empi_patient['nmhc_mrn']
        # puts empi_patient['ethnicity']
        puts 'begin moomin'
        puts empi_patient.keys
        puts 'end moomin'
        empi_patients << empi_patient
      end
    end
  end
  empi_patients
end

def format_address(empi_patient)
  [empi_patient['address_line1'], empi_patient['city'], empi_patient['state'], empi_patient['zip']].compact.join(' ')
end