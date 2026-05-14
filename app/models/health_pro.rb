class HealthPro < ApplicationRecord
  has_paper_trail
  belongs_to :batch_health_pro
  has_many :matches
  has_many :empi_matches
  has_many :duplicate_matches

  STATUS_PENDING              = 'pending'
  STATUS_PREVIOUSLY_MATCHED   = 'previously matched'
  STATUS_MATCHABLE            = 'matchable'
  STATUS_UNMATCHABLE          = 'unmatchable'
  STATUS_MATCHED              = 'matched'
  STATUS_DECLINED             = 'declined'
  STATUS_ADDED                = 'added'
  STATUSES = [STATUS_MATCHABLE, STATUS_UNMATCHABLE, STATUS_MATCHED, STATUS_PREVIOUSLY_MATCHED, STATUS_DECLINED, STATUS_ADDED]

  SEX_SexAtBirth_Male = 'SexAtBirth_Male'
  SEX_SexAtBirth_Female = 'SexAtBirth_Female'
  SEX_SexAtBirth_Intersex = 'SexAtBirth_Intersex'
  SEX_SexAtBirth_None = 'SexAtBirth_None'
  SEX_PMI_PreferNotToAnswer = 'PMI_PreferNotToAnswer'
  SEX_PMI_Skip = 'PMI_Skip'
  SEX_SexAtBirth_SexAtBirthNoneOfThese = 'PMI_Skip'
  SEXES = [SEX_SexAtBirth_Male, SEX_SexAtBirth_Female, SEX_SexAtBirth_Intersex, SEX_SexAtBirth_None, SEX_PMI_PreferNotToAnswer, SEX_PMI_Skip, SEX_SexAtBirth_SexAtBirthNoneOfThese]

  # SEX_MALE = 'Male'
  # SEX_FEMALE = 'Female'
  # SEX_SexAtBirth_Intersex = 'Intersex'
  # SEX_NONE = 'None of these describe me (optional free text)'
  # SEXES = [SEX_MALE, SEX_FEMALE, SEX_INTERSEX, SEX_NONE]

  YES = '1'
  NO = '0'

  BIOSPECIMEN_LOCATION_NORTHWESTERN = 'hpo-site-nwfeinberggalter'
  BIOSPECIMEN_LOCATION_NORTHWESTERN_DELNOR = 'hpo-site-nwdelnorhospital'
  BIOSPECIMEN_LOCATION_NORTHWESTERN_VERNON_HILLS = 'hpo-site-nwvernonhillsicc'
  BIOSPECIMEN_LOCATION_NORTHWESTERN_GRAYSLAKE = 'hpo-site-nwmedicinegrayslake'
  BIOSPECIMEN_LOCATIONS = [BIOSPECIMEN_LOCATION_NORTHWESTERN, BIOSPECIMEN_LOCATION_NORTHWESTERN_DELNOR, BIOSPECIMEN_LOCATION_NORTHWESTERN_VERNON_HILLS, BIOSPECIMEN_LOCATION_NORTHWESTERN_GRAYSLAKE]

  PAIRED_ORGANIZATION_NORTHWESTERN = 'ILLINOIS_NORTHWESTERN'
  PAIRED_ORGANIZATION_NEAR_NORTH = 'ILLINOIS_NEAR_NORTH'
  PAIRED_ORGANIZATION_ILLINOIS_ERIE = 'ILLINOIS_ERIE'
  PAIRED_ORGANIZATIONS = [PAIRED_ORGANIZATION_NORTHWESTERN, PAIRED_ORGANIZATION_NEAR_NORTH, PAIRED_ORGANIZATION_ILLINOIS_ERIE]

  PAIRED_SITE_NEAR_NORTH_NW_FEINBERG_GALTER = 'hpo-site-nearnorthnwfeinberggalter'
  PAIRED_SITE_FEINBERG_GALTER = 'hpo-site-nwfeinberggalter'
  PAIRED_SITE_ERIE_FEINBERG_GALTER = 'hpo-site-erienwfeinberggalter'
  PAIRED_SITE_DELNOR_HOSPITAL = 'hpo-site-nwdelnorhospital'
  PAIRED_SITE_VERNON_HILLS_ICC = 'hpo-site-nwvernonhillsicc'
  PAIRED_SITE_GRAYSLAKE = 'hpo-site-nwmedicinegrayslake'
  PAIRED_SITES = [PAIRED_SITE_NEAR_NORTH_NW_FEINBERG_GALTER, PAIRED_SITE_FEINBERG_GALTER, PAIRED_SITE_ERIE_FEINBERG_GALTER, PAIRED_SITE_DELNOR_HOSPITAL, PAIRED_SITE_VERNON_HILLS_ICC, PAIRED_SITE_GRAYSLAKE]

  HEALTH_PRO_CONSENT_STATUS_UNDETERMINED = 'Undetermined'
  HEALTH_PRO_CONSENT_STATUS_DECLINED = 'Declined'
  HEALTH_PRO_CONSENT_STATUS_CONSENTED = 'Consented'
  HEALTH_PRO_CONSENT_STATUS_WITHDRAWN =  'Withdrawn'
  HEALTH_PRO_CONSENT_STATUSES = [HEALTH_PRO_CONSENT_STATUS_UNDETERMINED, HEALTH_PRO_CONSENT_STATUS_DECLINED, HEALTH_PRO_CONSENT_STATUS_CONSENTED]

  HEALTH_PRO_API_GENERAL_CONSENT_STATUS_UNSET = 'UNSET'
  HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED = 'SUBMITTED'
  HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_NO_CONSENT = 'SUBMITTED_NO_CONSENT'
  HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_NOT_SURE = 'SUBMITTED_NOT_SURE'
  HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_INVALID = 'SUBMITTED_INVALID'
  HEALTH_PRO_API_AWARDEE_CONSENT_STATUS_YES = 'yes'
  HEALTH_PRO_API_AWARDEE_CONSENT_STATUS_NO = 'no'
  HEALTH_PRO_API_GENERAL_CONSENT_STATUSES = [HEALTH_PRO_API_GENERAL_CONSENT_STATUS_UNSET, HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED, HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_NO_CONSENT, HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_NOT_SURE, HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_INVALID, HEALTH_PRO_API_AWARDEE_CONSENT_STATUS_YES, HEALTH_PRO_API_AWARDEE_CONSENT_STATUS_NO]
  HEALTH_PRO_API_GENERAL_CONSENT_STATUSES_DECLINED = [HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_NO_CONSENT, HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_NOT_SURE, HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED_INVALID, HEALTH_PRO_API_AWARDEE_CONSENT_STATUS_NO]

  HEALTH_PRO_API_EHR_CONSENT_STATUS_UNSET = 'UNSET'
  HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED = 'SUBMITTED'
  HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_NO_CONSENT = 'SUBMITTED_NO_CONSENT'
  HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_NOT_SURE = 'SUBMITTED_NOT_SURE'
  HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_INVALID = 'SUBMITTED_INVALID'
  HEALTH_PRO_API_AWARDEE_EHR_CONSENT_STATUS_YES = 'yes'
  HEALTH_PRO_API_AWARDEE_EHR_CONSENT_STATUS_NO = 'no'
  HEALTH_PRO_API_EHR_CONSENT_STATUSES = [HEALTH_PRO_API_EHR_CONSENT_STATUS_UNSET, HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED, HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_NO_CONSENT, HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_NOT_SURE, HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_INVALID, HEALTH_PRO_API_AWARDEE_EHR_CONSENT_STATUS_YES, HEALTH_PRO_API_AWARDEE_EHR_CONSENT_STATUS_NO]
  HEALTH_PRO_API_EHR_CONSENT_STATUSES_DECLINED = [HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_NO_CONSENT, HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_NOT_SURE, HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED_INVALID, HEALTH_PRO_API_AWARDEE_EHR_CONSENT_STATUS_NO]

  HEALTH_PRO_API_WITHDRAWAL_STATUS_NOT_WITHDRAWN = 'NOT_WITHDRAWN'
  HEALTH_PRO_API_WITHDRAWAL_STATUS_NO_USE = 'NO_USE'
  HEALTH_PRO_API_AWARDEE_WITHDRAWAL_STATUS_WITHDRAWN = 'withdrawn'
  HEALTH_PRO_API_WITHDRAWAL_STATUSES_NON_SUBMITTED = [HEALTH_PRO_API_WITHDRAWAL_STATUS_NOT_WITHDRAWN, HEALTH_PRO_API_WITHDRAWAL_STATUS_NO_USE]

  HEALTH_PRO_API_DEACTIVATION_STATUS_NOT_SUSPENDED = 'NOT_SUSPENDED'
  HEALTH_PRO_API_DEACTIVATION_STATUS_NO_CONTACT = 'NO_CONTACT'
  # New values from deactivationStatus field from Awardee InSite API
  HEALTH_PRO_API_DEACTVATION_STATUS_NOT_DEACTIVATED = 'not_deactivated'
  HEALTH_PRO_API_DEACTIVATION_STATUS_DEACTIVATED = 'deactivated'
  HEALTH_PRO_API_DEACTIVATION_STATUSES = [HEALTH_PRO_API_DEACTIVATION_STATUS_NOT_SUSPENDED, HEALTH_PRO_API_DEACTIVATION_STATUS_NO_CONTACT, HEALTH_PRO_API_DEACTVATION_STATUS_NOT_DEACTIVATED, HEALTH_PRO_API_DEACTIVATION_STATUS_DEACTIVATED]

  HEALTH_PRO_API_PARTICIPANT_STATUS_CORE_PARTICIPANT = 'FULL_PARTICIPANT'
  HEALTH_PRO_API_AWARDEE_PARTICIPANT_STATUS_CORE_PARTICIPANT = 'core_participant'

  HEALTH_PRO_API_RACE_UNSET = 'UNSET'
  HEALTH_PRO_API_RACE_WHITE = 'WHITE'
  HEALTH_PRO_API_RACE_BLACK_OR_AFRICAN_AMERICAN = 'BLACK_OR_AFRICAN_AMERICAN'
  HEALTH_PRO_API_RACE_HLS_AND_MORE_THAN_ONE_OTHER_RACE = 'HLS_AND_MORE_THAN_ONE_OTHER_RACE'
  HEALTH_PRO_API_RACE_HISPANIC_LATINO_OR_SPANISH = 'HISPANIC_LATINO_OR_SPANISH'
  HEALTH_PRO_API_RACE_UNMAPPED = 'UNMAPPED'
  HEALTH_PRO_API_RACE_ASIAN = 'ASIAN'
  HEALTH_PRO_API_RACE_MIDDLE_EASTERN_OR_NORTH_AFRICAN = 'MIDDLE_EASTERN_OR_NORTH_AFRICAN'
  HEALTH_PRO_API_RACE_HLS_AND_WHITE = 'HLS_AND_WHITE'
  HEALTH_PRO_API_RACE_AMERICAN_INDIAN_OR_ALASKA_NATIVE = 'AMERICAN_INDIAN_OR_ALASKA_NATIVE'
  HEALTH_PRO_API_RACE_HLS_AND_BLACK = 'HLS_AND_BLACK'
  HEALTH_PRO_API_RACE_PREFER_NOT_TO_SAY = 'PREFER_NOT_TO_SAY'
  HEALTH_PRO_API_RACE_HLS_AND_ONE_OTHER_RACE = 'HLS_AND_ONE_OTHER_RACE'
  HEALTH_PRO_API_RACE_MORE_THAN_ONE_RACE = 'MORE_THAN_ONE_RACE'
  HEALTH_PRO_API_RACE_OTHER_RACE = 'OTHER_RACE'
  HEALTH_PRO_API_RACE_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER = 'NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER'
  HEALTH_PRO_API_RACES = [HEALTH_PRO_API_RACE_UNSET, HEALTH_PRO_API_RACE_WHITE, HEALTH_PRO_API_RACE_BLACK_OR_AFRICAN_AMERICAN, HEALTH_PRO_API_RACE_HLS_AND_MORE_THAN_ONE_OTHER_RACE, HEALTH_PRO_API_RACE_HISPANIC_LATINO_OR_SPANISH, HEALTH_PRO_API_RACE_UNMAPPED, HEALTH_PRO_API_RACE_ASIAN, HEALTH_PRO_API_RACE_MIDDLE_EASTERN_OR_NORTH_AFRICAN, HEALTH_PRO_API_RACE_HLS_AND_WHITE, HEALTH_PRO_API_RACE_AMERICAN_INDIAN_OR_ALASKA_NATIVE, HEALTH_PRO_API_RACE_HLS_AND_BLACK, HEALTH_PRO_API_RACE_PREFER_NOT_TO_SAY, HEALTH_PRO_API_RACE_HLS_AND_ONE_OTHER_RACE, HEALTH_PRO_API_RACE_MORE_THAN_ONE_RACE, HEALTH_PRO_API_RACE_OTHER_RACE, HEALTH_PRO_API_RACE_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER]

  # HEALTH_PRO_RACE_ETHNICITY_WHITE = 'White'
  # HEALTH_PRO_RACE_ETHNICITY_BLACK_OR_AFRICAN_AMERICAN = 'Black or African American'
  # HEALTH_PRO_RACE_ETHNICITY_HLS_AND_MORE_THAN_ONE_OTHER_RACE  = 'H/L/S and more than one other race'
  # HEALTH_PRO_RACE_ETHNICITY_HISPANIC_LATINO_OR_SPANISH = 'Hispanic, Latino, or Spanish'
  # HEALTH_PRO_RACE_ETHNICITY_SKIP = 'Skip'
  # HEALTH_PRO_RACE_ETHNICITY_ASIAN = 'Asian'
  # HEALTH_PRO_RACE_ETHNICITY_MIDDLE_EASTERN_OR_NORTH_AFRICAN = 'Middle Eastern or North African'
  # HEALTH_PRO_RACE_ETHNICITY_HLS_AND_WHITE = 'H/L/S and White'
  # HEALTH_PRO_RACE_ETHNICITY_AMERICAN_INDIAN_ALASKA_NATIVE = 'American Indian / Alaska Native'
  # HEALTH_PRO_RACE_ETHNICITY_HLS_AND_BLACK = 'H/L/S and Black'
  # HEALTH_PRO_RACE_ETHNICITY_PREFER_NOT_TO_ANSWER = 'Prefer Not to Answer'
  # HEALTH_PRO_RACE_ETHNICITY_HLS_AND_ONE_OTHER_RACE  = 'H/L/S and one other race'
  # HEALTH_PRO_RACE_ETHNICITY_MORE_THAN_ONE_RACE = 'More than one race'
  # HEALTH_PRO_RACE_ETHNICITY_OTHER = 'Other'
  # HEALTH_PRO_RACE_ETHNICITY_NATIVE_HAWAIIAN_OTHER_PACIFIC_ISLANDER = 'Native Hawaiian or Other Pacific Islander'
  # HEALTH_PRO_RACE_ETHNICITIES = [HEALTH_PRO_RACE_ETHNICITY_WHITE, HEALTH_PRO_RACE_ETHNICITY_BLACK_OR_AFRICAN_AMERICAN, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_MORE_THAN_ONE_OTHER_RACE, HEALTH_PRO_RACE_ETHNICITY_HISPANIC_LATINO_OR_SPANISH, HEALTH_PRO_RACE_ETHNICITY_SKIP, HEALTH_PRO_RACE_ETHNICITY_ASIAN, HEALTH_PRO_RACE_ETHNICITY_MIDDLE_EASTERN_OR_NORTH_AFRICAN, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_WHITE, HEALTH_PRO_RACE_ETHNICITY_AMERICAN_INDIAN_ALASKA_NATIVE, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_BLACK, HEALTH_PRO_RACE_ETHNICITY_PREFER_NOT_TO_ANSWER, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_ONE_OTHER_RACE, HEALTH_PRO_RACE_ETHNICITY_MORE_THAN_ONE_RACE, HEALTH_PRO_RACE_ETHNICITY_OTHER, HEALTH_PRO_RACE_ETHNICITY_NATIVE_HAWAIIAN_OTHER_PACIFIC_ISLANDER]

  after_initialize :set_defaults

  scope :declined, -> do
    joins("JOIN (SELECT hp2.pmi_id, max(hp2.id) as id
                 FROM health_pros hp2
                 WHERE hp2.pmi_id IN(
                                      SELECT hp3.pmi_id
                                      FROM health_pros hp3
                                      WHERE hp3.status = 'declined'
                                    )
                 GROUP BY hp2.pmi_id
                 ) hp4 ON health_pros.pmi_id = hp4.pmi_id AND health_pros.id = hp4.id").where('health_pros.status != ? AND EXISTS (SELECT 1 FROM health_pros hp5 WHERE health_pros.id != hp5.id AND health_pros.pmi_id = hp5.pmi_id AND hp5.status = ?)', HealthPro::STATUS_DECLINED, HealthPro::STATUS_DECLINED)
  end

  scope :by_status, ->(status) do
    if status.present?
     where(status: status)
    end
  end

  scope :by_paired_organization, ->(paired_organization) do
    if !['all (not UNSET)','all'].include?(paired_organization)
      p = where(paired_organization: paired_organization)
    end

    if paired_organization == 'all (not UNSET)'
      p = where("paired_organization != 'UNSET'")
    end

    if p.nil?
      p =  all
    end
    p
  end

  scope :by_paired_site, ->(paired_site) do
    if !['all (not UNSET)','all'].include?(paired_site)
     p = where(paired_site: paired_site)
    end

    if paired_site == 'all (not UNSET)'
      p = where("paired_site != 'UNSET'")
    end

    if p.nil?
      p =  all
    end
    p
  end
  scope :by_biospecimens_location, ->(biospecimens_location) do
    if !['all'].include?(biospecimens_location)
      p = where('health_pros.biospecimens_location = ?', biospecimens_location)
    else
      p =  all
    end

    p
  end

  scope :search_across_fields_declined, ->(search_token, options={}) do
    if search_token
      search_token.downcase!
    end
    options = { sort_column: 'last_name', sort_direction: 'asc' }.merge(options)

    if search_token
      p = where(["lower(health_pros.pmi_id) like ? OR lower(health_pros.last_name) like ? OR lower(health_pros.first_name) like ? OR lower(health_pros.paired_organization) like ? OR lower(health_pros.paired_site) like ? OR lower(health_pros.biospecimens_location) like ?", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%"])
    end

    sort = "health_pros." + options[:sort_column] + ' ' + options[:sort_direction] + ', health_pros.id ASC'
    p = p.nil? ? order(sort) : p.order(sort)

    p
  end

  scope :search_across_fields, ->(search_token, options={}) do
    if search_token
      search_token.downcase!
    end
    options = { sort_column: 'last_name', sort_direction: 'asc' }.merge(options)

    if search_token
      p = where(["lower(pmi_id) like ? OR lower(last_name) like ? OR lower(first_name) like ? OR lower(email) like ? OR lower(street_address) like ? OR lower(street_address2) like ? OR lower(city) like ? OR lower(state) like ? OR lower(zip) like ?", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%"])
    end

    sort = options[:sort_column] + ' ' + options[:sort_direction] + ', health_pros.id ASC'
    p = p.nil? ? order(sort) : p.order(sort)

    p
  end

  scope :previously_declined, ->(pmi_id, batch_health_pro_id) do
    where('pmi_id = ? AND batch_health_pro_id != ? AND status = ?', pmi_id, batch_health_pro_id, HealthPro::STATUS_DECLINED)
  end

  # scope :for_ehr_submisison, -> { where(deactivation_status: HEALTH_PRO_API_DEACTIVATION_STATUS_NOT_SUSPENDED, withdrawal_status: 'NOT_WITHDRAWN', participant_status: HealthPro::HEALTH_PRO_API_PARTICIPANT_STATUS_CORE_PARTICIPANT, biospecimens_location: HealthPro::BIOSPECIMEN_LOCATIONS, general_consent_status: 'SUBMITTED', ehr_consent_status: 'SUBMITTED' }

  def determine_matches
    # if (self.paired_organization == HealthPro::PAIRED_ORGANIZATION_NORTHWESTERN || self.paired_organization.blank? || ([HealthPro::PAIRED_ORGANIZATION_NEAR_NORTH, HealthPro::PAIRED_ORGANIZATION_ILLINOIS_ERIE].include?(self.paired_organization) && (self.paired_site.blank? || HealthPro::PAIRED_SITES.include?(self.paired_site)))) && HealthPro.previously_declined(self.pmi_id, self.batch_health_pro_id).count == 0
    if (self.paired_organization == HealthPro::PAIRED_ORGANIZATION_NORTHWESTERN || self.paired_organization == 'UNSET' || ([HealthPro::PAIRED_ORGANIZATION_NEAR_NORTH, HealthPro::PAIRED_ORGANIZATION_ILLINOIS_ERIE].include?(self.paired_organization) && (self.paired_site == 'UNSET' || HealthPro::PAIRED_SITES.include?(self.paired_site)))) && HealthPro.previously_declined(self.pmi_id, self.batch_health_pro_id).count == 0
      matched_pmi_patients = Patient.not_deleted.where(pmi_id: self.pmi_id)
      matched_demographic_patients = Patient.not_deleted.no_previously_declined_match.by_matchable_criteria(self.first_name, self.last_name)

      if matched_pmi_patients.count == 1
        self.status = HealthPro::STATUS_PREVIOUSLY_MATCHED
      elsif matched_demographic_patients.size > 0
        self.status = HealthPro::STATUS_MATCHABLE
        matched_demographic_patients.each do |matched_demographic_patient|
          matches.build(patient: matched_demographic_patient)
        end
      else
        self.status = HealthPro::STATUS_MATCHABLE
      end
    else
      self.status = HealthPro::STATUS_UNMATCHABLE
    end
  end

  def determine_duplicates
    matched_demographic_patients = Patient.not_deleted.by_potential_duplicates(self.first_name, self.last_name, self.date_of_birth)
    if matched_demographic_patients.size > 0
      matched_demographic_patients.each do |matched_demographic_patient|
        self.duplicate_matches.build(patient: matched_demographic_patient)
      end
    end
  end

  def determine_empi_matches
    empi_params = {}
    empi_patients = []
    error = nil
    study_tracker_api = StudyTrackerApi.new
    empi_params[:proxy_user] = self.batch_health_pro.created_user
    empi_params[:first_name] = self.first_name
    empi_params[:last_name] = self.last_name
    empi_params[:birth_date] = self.date_of_birth
    empi_params[:address] = self.address
    empi_params[:gender] = self.sex_to_patient_gender
    empi_results = study_tracker_api.empi_lookup(empi_params)
    if empi_results[:error].present? || empi_results[:response]['error'].present?
    else
      empi_results[:response]['patients'].each do |empi_patient|
        empi_race_matches = []
        empi_patient['races'].each do |empi_race|
          race = Race.where(name: empi_race).first
          if race.present?
            empi_race_matches << EmpiRaceMatch.new(race_id: race.id)
          end
        end
        if empi_patient['nmhc_mrn'].present?
          self.empi_matches.build(first_name: empi_patient['first_name'], last_name: empi_patient['last_name'], birth_date: empi_patient['birth_date'], gender: empi_patient['gender'], address: format_address(empi_patient), nmhc_mrn: empi_patient['nmhc_mrn'], ethnicity: empi_patient['ethnicity'], empi_race_matches: empi_race_matches)
        end
      end
    end
  end

  def format_address(empi_patient)
    [empi_patient['address_line1'], empi_patient['city'], empi_patient['state'], empi_patient['zip']].compact.join(' ')
  end

  def matchable?
    self.status == HealthPro::STATUS_MATCHABLE
  end

  def address
    [self.street_address, self.street_address2, self.city, self.state, self.zip].compact.join(' ')
  end

  def pending_matches?
    pending_matches.any?
  end

  def pending_matches
    matches.by_status(Match::STATUS_PENDING)
  end

  def sex_to_patient_gender
    if self.sex == HealthPro::SEX_SexAtBirth_Male
      mapped = Patient::GENDER_MALE
    end

    if self.sex == HealthPro::SEX_SexAtBirth_Female
      mapped = Patient::GENDER_FEMALE
    end

    if mapped.present?
      mapped
    else
      Patient::GENDER_UNKNOWN_OR_NOT_REPORTED
    end
  end

  def latest_paired_organization
    last_health_pro.paired_organization
  end

  def latest_paired_site
    last_health_pro.paired_site
  end

  def latest_biospecimens_location
    last_health_pro.biospecimens_location
  end

  def last_health_pro
    @last_health_pro ||= HealthPro.find(HealthPro.where(pmi_id: self.pmi_id).maximum(:id))
  end

  def undecline!
    health_pro = HealthPro.where('pmi_id = ? AND status = ?', self.pmi_id, HealthPro::STATUS_DECLINED).first
    health_pro.status = HealthPro::STATUS_MATCHABLE
    health_pro.save
  end

  def set_digital_health_status_fitbit_complete_y
    if digital_health_consent.present?
      if self.digital_health_consent_to_json['fitbit']
        self.digital_health_status_fitbit_complete_y = self.digital_health_consent_to_json['fitbit']['status']
      end
    end
  end

  def set_digital_health_status_fitbit_completion_date_d
    if digital_health_consent.present?
      if self.digital_health_consent_to_json['fitbit']
        if self.digital_health_consent_to_json['fitbit']['authoredTime'].present?
          self.digital_health_status_fitbit_completion_date_d = Date.parse(self.digital_health_consent_to_json['fitbit']['authoredTime']).to_s
        end
      end
    end
  end

  def set_digital_health_status_apple_health_kit_complete_y
    if digital_health_consent.present?
      if self.digital_health_consent_to_json['appleHealthKit']
        self.digital_health_status_apple_health_kit_complete_y = self.digital_health_consent_to_json['appleHealthKit']['status']
      end
    end
  end

  def set_digital_health_status_apple_health_kit_completion_date_d
    if digital_health_consent.present?
      if self.digital_health_consent_to_json['appleHealthKit']
        if self.digital_health_consent_to_json['appleHealthKit']['authoredTime'].present?
          self.digital_health_status_apple_health_kit_completion_date_d = Date.parse(self.digital_health_consent_to_json['appleHealthKit']['authoredTime'])
        end
      end
    end
  end

  def set_digital_health_status_apple_health_ehr_complete_y
    if digital_health_consent.present?
      if self.digital_health_consent_to_json['appleEHR']
        self.digital_health_status_apple_health_ehr_complete_y = self.digital_health_consent_to_json['appleEHR']['status']
      end
    end
  end

  def set_digital_health_status_apple_health_ehr_completion_date_d
    if digital_health_consent.present?
      if self.digital_health_consent_to_json['appleEHR']
        if self.digital_health_consent_to_json['appleEHR']['authoredTime'].present?
          self.digital_health_status_apple_health_ehr_completion_date_d = Date.parse(self.digital_health_consent_to_json['appleEHR']['authoredTime'])
        end
      end
    end
  end

  def set_digital_health_fields
    set_digital_health_status_fitbit_complete_y
    set_digital_health_status_fitbit_completion_date_d
    set_digital_health_status_apple_health_kit_complete_y
    set_digital_health_status_apple_health_kit_completion_date_d
    set_digital_health_status_apple_health_ehr_complete_y
    set_digital_health_status_apple_health_ehr_completion_date_d
  end

  def digital_health_consent_to_json
    if self.digital_health_consent.present?
      @digital_health_consent ||= JSON.parse(self.digital_health_consent.gsub('=>', ':'))
    end
  end

  private
    def set_defaults
      if self.new_record? && self.status.blank?
        self.status = HealthPro::STATUS_PENDING
      end
    end
end