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

  SEX_MALE = 'Male'
  SEX_FEMALE = 'Female'
  SEX_INTERSEX = 'Intersex'
  SEX_NONE = 'None of these describe me (optional free text)'
  SEXES = [SEX_MALE, SEX_FEMALE, SEX_INTERSEX, SEX_NONE]

  YES = '1'
  NO = '0'

  BIOSPECIMEN_LOCATION_NORTHWESTERN = 'nwfeinberggalter'
  BIOSPECIMEN_LOCATION_NORTHWESTERN_DELNOR = 'nwdelnorhospital'
  BIOSPECIMEN_LOCATION_NORTHWESTERN_VERNON_HILLS = 'nwvernonhillsicc'
  BIOSPECIMEN_LOCATIONS = [BIOSPECIMEN_LOCATION_NORTHWESTERN, BIOSPECIMEN_LOCATION_NORTHWESTERN_DELNOR, BIOSPECIMEN_LOCATION_NORTHWESTERN_VERNON_HILLS]

  PAIRED_ORGANIZATION_NORTHWESTERN = 'ILLINOIS_NORTHWESTERN'
  PAIRED_ORGANIZATION_NEARH_NORTH = 'ILLINOIS_NEAR_NORTH'
  PAIRED_ORGANIZATION_ILLINOIS_ERIE = 'ILLINOIS_ERIE'
  PAIRED_ORGANIZATIONS = [PAIRED_ORGANIZATION_NORTHWESTERN, PAIRED_ORGANIZATION_NEARH_NORTH, PAIRED_ORGANIZATION_ILLINOIS_ERIE]

  PAIRED_SITE_NEAR_NORTH_NW_FEINBERG_GALTER = 'nearnorthnwfeinberggalter'
  PAIRED_SITE_FEINBERG_GALTER = 'nwfeinberggalter'
  PAIRED_SITE_ERIE_FEINBERG_GALTER = 'erienwfeinberggalter'
  PAIRED_SITE_DELNOR_HOSPITAL = 'nwdelnorhospital'
  PAIRED_SITE_VERNON_HILLS_ICC = 'nwvernonhillsicc'
  PAIRED_SITES = [PAIRED_SITE_NEAR_NORTH_NW_FEINBERG_GALTER, PAIRED_SITE_FEINBERG_GALTER, PAIRED_SITE_ERIE_FEINBERG_GALTER, PAIRED_SITE_DELNOR_HOSPITAL, PAIRED_SITE_VERNON_HILLS_ICC]

  HEALTH_PRO_CONSENT_STATUS_UNDETERMINED = 'Undetermined'
  HEALTH_PRO_CONSENT_STATUS_DECLINED = 'Declined'
  HEALTH_PRO_CONSENT_STATUS_CONSENTED = 'Consented'
  HEALTH_PRO_CONSENT_STATUS_WITHDRAWN =  'Withdrawn'
  HEALTH_PRO_CONSENT_STATUSES = [HEALTH_PRO_CONSENT_STATUS_UNDETERMINED, HEALTH_PRO_CONSENT_STATUS_DECLINED, HEALTH_PRO_CONSENT_STATUS_CONSENTED]

  HEALTH_PRO_PARTICIPANT_STATUS_CORE_PARTICIPANT = 'Core Participant'

  HEALTH_PRO_RACE_ETHNICITY_WHITE = 'White'
  HEALTH_PRO_RACE_ETHNICITY_BLACK_OR_AFRICAN_AMERICAN = 'Black or African American'
  HEALTH_PRO_RACE_ETHNICITY_HLS_AND_MORE_THAN_ONE_OTHER_RACE  = 'H/L/S and more than one other race'
  HEALTH_PRO_RACE_ETHNICITY_HISPANIC_LATINO_OR_SPANISH = 'Hispanic, Latino, or Spanish'
  HEALTH_PRO_RACE_ETHNICITY_SKIP = 'Skip'
  HEALTH_PRO_RACE_ETHNICITY_ASIAN = 'Asian'
  HEALTH_PRO_RACE_ETHNICITY_MIDDLE_EASTERN_OR_NORTH_AFRICAN = 'Middle Eastern or North African'
  HEALTH_PRO_RACE_ETHNICITY_HLS_AND_WHITE = 'H/L/S and White'
  HEALTH_PRO_RACE_ETHNICITY_AMERICAN_INDIAN_ALASKA_NATIVE = 'American Indian / Alaska Native'
  HEALTH_PRO_RACE_ETHNICITY_HLS_AND_BLACK = 'H/L/S and Black'
  HEALTH_PRO_RACE_ETHNICITY_PREFER_NOT_TO_ANSWER = 'Prefer Not to Answer'
  HEALTH_PRO_RACE_ETHNICITY_HLS_AND_ONE_OTHER_RACE  = 'H/L/S and one other race'
  HEALTH_PRO_RACE_ETHNICITY_MORE_THAN_ONE_RACE = 'More than one race'
  HEALTH_PRO_RACE_ETHNICITY_OTHER = 'Other'
  HEALTH_PRO_RACE_ETHNICITY_NATIVE_HAWAIIAN_OTHER_PACIFIC_ISLANDER = 'Native Hawaiian or Other Pacific Islander'
  HEALTH_PRO_RACE_ETHNICITIES = [HEALTH_PRO_RACE_ETHNICITY_WHITE, HEALTH_PRO_RACE_ETHNICITY_BLACK_OR_AFRICAN_AMERICAN, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_MORE_THAN_ONE_OTHER_RACE, HEALTH_PRO_RACE_ETHNICITY_HISPANIC_LATINO_OR_SPANISH, HEALTH_PRO_RACE_ETHNICITY_SKIP, HEALTH_PRO_RACE_ETHNICITY_ASIAN, HEALTH_PRO_RACE_ETHNICITY_MIDDLE_EASTERN_OR_NORTH_AFRICAN, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_WHITE, HEALTH_PRO_RACE_ETHNICITY_AMERICAN_INDIAN_ALASKA_NATIVE, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_BLACK, HEALTH_PRO_RACE_ETHNICITY_PREFER_NOT_TO_ANSWER, HEALTH_PRO_RACE_ETHNICITY_HLS_AND_ONE_OTHER_RACE, HEALTH_PRO_RACE_ETHNICITY_MORE_THAN_ONE_RACE, HEALTH_PRO_RACE_ETHNICITY_OTHER, HEALTH_PRO_RACE_ETHNICITY_NATIVE_HAWAIIAN_OTHER_PACIFIC_ISLANDER]

  after_initialize :set_defaults

  scope :by_status, ->(status) do
    if status.present?
     where(status: status)
    end
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

  def determine_matches
    if (self.paired_organization == HealthPro::PAIRED_ORGANIZATION_NORTHWESTERN || self.paired_organization.blank? || ([HealthPro::PAIRED_ORGANIZATION_NEARH_NORTH, HealthPro::PAIRED_ORGANIZATION_ILLINOIS_ERIE].include?(self.paired_organization) && (self.paired_site.blank? || HealthPro::PAIRED_SITES.include?(self.paired_site)))) && HealthPro.previously_declined(self.pmi_id, self.batch_health_pro_id).count == 0
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
    mapped = Patient::GENDERS.detect { |gender| gender == self.sex }
    if mapped.present?
      mapped
    else
      Patient::GENDER_UNKNOWN_OR_NOT_REPORTED
    end
  end

  private
    def set_defaults
      if self.new_record? && self.status.blank?
        self.status = HealthPro::STATUS_PENDING
      end
    end
end