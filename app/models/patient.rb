class Patient < ApplicationRecord
  include SoftDelete
  has_paper_trail
  has_many :invitation_code_assignments, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :patient_features, dependent: :destroy
  has_and_belongs_to_many :races
  has_one :patient_empi_match, dependent: :destroy
  accepts_nested_attributes_for :patient_features, allow_destroy: true

  ERROR_MESSAGE_FAILED_TO_ASSIGN_INVITATION_CODE = 'Failed to assign an invitation code.'

  REGISTRATION_STATUS_UNMATCHED = 'unmatched'
  REGISTRATION_STATUS_MATCHED = 'matched'
  REGISTRATION_STATUS_READY = 'ready'
  REGISTRATION_STATUS_REGISTERED = 'registered'
  REGISTRATION_STATUSES = [REGISTRATION_STATUS_UNMATCHED, REGISTRATION_STATUS_MATCHED, REGISTRATION_STATUS_READY, REGISTRATION_STATUS_REGISTERED]

  ETHNICITY_HISPANIC_OR_LATINO = 'Hispanic or Latino'
  ETHNICITY_NOT_HISPANIC_OR_LATINO = 'Not Hispanic or Latino'
  ETHNICITY_UNKNOWN_OR_NOT_REPORTED = 'Unknown or Not Reported'
  ETHNICITIES = [ETHNICITY_HISPANIC_OR_LATINO, ETHNICITY_NOT_HISPANIC_OR_LATINO, ETHNICITY_UNKNOWN_OR_NOT_REPORTED]

  GENDER_MALE = 'Male'
  GENDER_FEMALE = 'Female'
  GENDER_UNKNOWN_OR_NOT_REPORTED = 'Unknown or Not Reported'
  GENDERS = [GENDER_MALE, GENDER_FEMALE, GENDER_UNKNOWN_OR_NOT_REPORTED]

  validates :pmi_id, uniqueness: { case_sensitive: false }, allow_blank: true
  after_initialize :set_defaults
  after_create :save_default_patient_features

  scope :by_paired_site, ->(paired_site) do
    if paired_site.present? && paired_site != 'all'
      where(paired_site: paired_site)
    end
  end

  scope :by_registration_status, ->(registration_status) do
    if registration_status.present? && registration_status != 'all'
      where(registration_status: registration_status)
    end
  end

  scope :search_across_fields, ->(search_token, options={}) do
    if search_token
      search_token.downcase!
    end
    options = { sort_column: 'last_name', sort_direction: 'asc' }.merge(options)

    if search_token && search_token.split(' ').size > 1
      where_clauses = []
      where_clause_arguments = []
      conditions = ['lower(last_name) like ?', 'lower(first_name) like ?']
      conditions.each do |condition|
        condition_clauses = []
        search_token.split(' ').each do |st|
          condition_clauses << condition
          where_clause_arguments << "%#{st}%"
        end
        condition_clauses = condition_clauses.join(' OR ')
        where_clauses << "(#{condition_clauses})"
      end
      where_clauses = where_clauses.join(' AND ')
      where_clause_arguments << "%#{search_token}%"
      where_clause_arguments << "%#{search_token}%"
      where_clause_arguments << "%#{search_token}%"
      where_clause = ["(#{where_clauses}) OR lower(record_id) like ? OR lower(pmi_id) like ? OR lower(email) like ?", where_clause_arguments].flatten
      p = where(where_clause)
    else
      p = where(["lower(record_id) like ? OR lower(pmi_id) like ? OR lower(last_name) like ? OR lower(first_name) like ? OR lower(email) like ?", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%", "%#{search_token}%"])
    end

    if options[:sort_column]  == 'physical_measurements_completion_date'
      sort = options[:sort_column] + '::date ' + options[:sort_direction] + ', patients.id ASC'
    else
      sort = options[:sort_column] + ' ' + options[:sort_direction] + ', patients.id ASC'
    end
    p = p.nil? ? order(sort) : p.order(sort)
    p = p.where("last_name IS NOT NULL AND last_name !=''")

    p
  end

  scope :no_previously_declined_match, -> do
    where('NOT EXISTS (SELECT 1 FROM matches JOIN health_pros ON matches.health_pro_id = health_pros.id WHERE patients.id = matches.patient_id AND matches.status = ?)', Match::STATUS_DECLINED)
  end

  scope :by_matchable_criteria, ->(first_name, last_name) do
    first_names = Nickname.for(first_name.downcase).map(&:name)
    first_names << first_name.downcase
    first_names.uniq!
    where('registration_status = ? AND pmi_id IS NULL AND lower(first_name) in(?) AND lower(last_name) = ?', Patient::REGISTRATION_STATUS_UNMATCHED, first_names, last_name.try(:downcase))
  end

  scope :by_potential_duplicates, ->(first_name, last_name, birth_date) do
    begin
      birth_date = Date.parse(birth_date)
    rescue Exception => e
      birth_date = nil
    end

    first_names = Nickname.for(first_name.downcase).map(&:name)
    first_names << first_name.downcase
    first_names.uniq!
    where('registration_status != ? AND lower(first_name) in(?) AND lower(last_name) = ? AND birth_date = ?', Patient::REGISTRATION_STATUS_UNMATCHED, first_names, last_name.try(:downcase), birth_date)
  end

  def accepted_match
    matches.where(status: Match::STATUS_ACCEPTED).first
  end

  def invitation_code
     if invitation_code_assignments.is_active.any?
       invitation_code_assignments.is_active.first.invitation_code.code
     end
  end

  def full_name
    name = [first_name, last_name].compact.join(' ')
  end

  def self.create_or_update!(patient)
    p = Patient.not_deleted.where(record_id: patient['record_id']).first
    if p
      p.first_name = patient['first_name'] if p.first_name.blank?
      p.last_name = patient['last_name'] if p.last_name.blank?
      p.email = patient['email'] if p.email.blank?
    else
      p = Patient.new(record_id: patient['record_id'], first_name: patient['first_name'], last_name: patient['last_name'], email: patient['email'])
    end

    p.save!
    p
  end

  def assign_invitation_code(redcap_api, invitation_code=nil)
    invitation_code_assignment = nil
    if invitation_code.blank?
      invitation_code = InvitationCode.get_unassigned_invitation_code
    end

    begin
      Patient.transaction do
        redcap_patient_invitation_code = redcap_api.assign_invitation_code(record_id, invitation_code.code)
        raise "Error assigning invitation code #{invitation_code.code} to record_id #{record_id}." if redcap_patient_invitation_code[:error].present?
        invitation_code_assignment = invitation_code_assignments.build(invitation_code: invitation_code)
        save!
      end
    rescue Exception => e
      invitation_code_assignment = nil
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
    end
    invitation_code_assignment
  end

  def demographics_ready?
     ethnicity.present? && gender.present? && races.any?
  end

  def general_consent_status_ready?
    self.general_consent_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_CONSENTED || self.general_consent_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_DECLINED
  end

  def ehr_consent_status_ready?
    self.ehr_consent_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_CONSENTED || self.ehr_consent_status_display == HealthPro::HEALTH_PRO_CONSENT_STATUS_DECLINED
  end

  def ready?
    self.accepted_match && self.general_consent_status_ready? && self.ehr_consent_status_ready? && self.withdrawal_status_display.blank? && HealthPro::BIOSPECIMEN_LOCATIONS.include?(self.biospecimens_location) && self.participant_status == HealthPro::HEALTH_PRO_API_PARTICIPANT_STATUS_CORE_PARTICIPANT
  end

  def set_registration_status
    self.registration_status = determine_registration_status
  end

  def determine_registration_status
    determined = nil
    currently_ready = ready?

    if currently_ready
      determined = case registration_status
                   when Patient::REGISTRATION_STATUS_UNMATCHED, Patient::REGISTRATION_STATUS_MATCHED, Patient::REGISTRATION_STATUS_READY
                     Patient::REGISTRATION_STATUS_READY
                   else
                     registration_status
                   end
    else
      determined = case registration_status
                   when Patient::REGISTRATION_STATUS_UNMATCHED
                     Patient::REGISTRATION_STATUS_MATCHED
                   else
                     registration_status
                   end
    end
    determined
  end

  def registered?
    [Patient::REGISTRATION_STATUS_REGISTERED].include?(self.registration_status)
  end

  def matched?
    [Patient::REGISTRATION_STATUS_MATCHED].include?(self.registration_status)
  end

  def match
    if matches.any?
      matches.first
    end
  end

  def general_consent_status_display
    if self.general_consent_status.blank? || (self.general_consent_status == HealthPro::HEALTH_PRO_API_GENERAL_CONSENT_STATUS_UNSET && self.general_consent_date.blank?)
      HealthPro::HEALTH_PRO_CONSENT_STATUS_UNDETERMINED
    elsif HealthPro::HEALTH_PRO_API_GENERAL_CONSENT_STATUSES_DECLINED.include?(self.general_consent_status) && self.general_consent_date.present?
      HealthPro::HEALTH_PRO_CONSENT_STATUS_DECLINED
    elsif self.general_consent_status == HealthPro::HEALTH_PRO_API_GENERAL_CONSENT_STATUS_SUBMITTED && self.general_consent_date.present?
      HealthPro::HEALTH_PRO_CONSENT_STATUS_CONSENTED
    end
  end

  def ehr_consent_status_display
    if self.ehr_consent_status.blank? || (self.ehr_consent_status == HealthPro::HEALTH_PRO_API_EHR_CONSENT_STATUS_UNSET && self.ehr_consent_date.blank?)
      HealthPro::HEALTH_PRO_CONSENT_STATUS_UNDETERMINED
    elsif HealthPro::HEALTH_PRO_API_EHR_CONSENT_STATUSES_DECLINED.include?(self.ehr_consent_status) && self.ehr_consent_date.present?
      HealthPro::HEALTH_PRO_CONSENT_STATUS_DECLINED
    elsif self.ehr_consent_status == HealthPro::HEALTH_PRO_API_EHR_CONSENT_STATUS_SUBMITTED && self.ehr_consent_date.present?
      HealthPro::HEALTH_PRO_CONSENT_STATUS_CONSENTED
    end
  end

  def withdrawal_status_display
    if self.withdrawal_status == HealthPro::HEALTH_PRO_API_WITHDRAWAL_STATUS_NOT_WITHDRAWN && self.withdrawal_date.blank?
      nil
    elsif self.withdrawal_status == HealthPro::HEALTH_PRO_API_WITHDRAWAL_STATUS_NO_USE  && self.withdrawal_date.present?
      HealthPro::HEALTH_PRO_CONSENT_STATUS_WITHDRAWN
    end
  end

  def health_pro_race_ethnicity
    if health_pro.present?
      health_pro.race_ethnicity
    end
  end

  def health_pro_sex
    if health_pro.present?
      health_pro.sex
    end
  end

  def health_pro_address1
    if health_pro.present?
      health_pro.street_address
    end
  end

  def health_pro_address2
    if health_pro.present?
      health_pro.street_address2
    end
  end

  def health_pro_city
    if health_pro.present?
      health_pro.city
    end
  end

  def health_pro_state
    if health_pro.present?
      health_pro.state
    end
  end

  def health_pro_zip
    if health_pro.present?
      health_pro.zip
    end
  end

  def wq_program_update_status
    if health_pro.present?
      health_pro.program_update
    end
  end

  def wq_program_update_date
    if health_pro.present?
      health_pro.date_of_program_update
    end
  end

  def valid_demographics?
    if self.first_name.blank?
      self.errors.add(:first_name, "First name can't be blank.")
    end

    if self.last_name.blank?
      self.errors.add(:last_name, "Last name can't be blank.")
    end

    if self.birth_date.blank?
      self.errors.add(:birth_date, "Birthdate can't be blank.")
    end

    self.errors.empty?
  end

  def allow_health_pro_race_ethnicity_override?
    accepted_match && !registered? && !health_pro_race_ethnicity.blank?
  end

  def mapped_health_pro_race
    map_health_pro_race_ethnicity[:race]
  end

  def mapped_health_pro_ethnicity
    map_health_pro_race_ethnicity[:ethnicity]
  end

  def map_health_pro_race_ethnicity
    mapped_race_ethnicity = { race: nil, racce_id: nil, ethnicity: nil }
    case health_pro_race_ethnicity
    when HealthPro::HEALTH_PRO_API_RACE_WHITE
      mapped_race_ethnicity[:race] = Race::RACE_WHITE
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_BLACK_OR_AFRICAN_AMERICAN
      mapped_race_ethnicity[:race] = Race::RACE_BLACK_AFRICAN_AMERICAN
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_HLS_AND_MORE_THAN_ONE_OTHER_RACE
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_HISPANIC_OR_LATINO
    when HealthPro::HEALTH_PRO_API_RACE_HISPANIC_LATINO_OR_SPANISH
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_HISPANIC_OR_LATINO
    when HealthPro::HEALTH_PRO_API_RACE_UNMAPPED, HealthPro::HEALTH_PRO_API_RACE_UNSET
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_ASIAN
      mapped_race_ethnicity[:race] = Race::RACE_ASIAN
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_MIDDLE_EASTERN_OR_NORTH_AFRICAN
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_HLS_AND_WHITE
      mapped_race_ethnicity[:race] = Race::RACE_WHITE
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_HISPANIC_OR_LATINO
    when HealthPro::HEALTH_PRO_API_RACE_AMERICAN_INDIAN_OR_ALASKA_NATIVE
      mapped_race_ethnicity[:race] = Race::RACE_AMERICAN_INDIAN_ALASKA_NATIVE
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_HLS_AND_BLACK
      mapped_race_ethnicity[:race] = Race::RACE_BLACK_AFRICAN_AMERICAN
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_HISPANIC_OR_LATINO
    when HealthPro::HEALTH_PRO_API_RACE_PREFER_NOT_TO_SAY
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_HLS_AND_ONE_OTHER_RACE
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_HISPANIC_OR_LATINO
    when HealthPro::HEALTH_PRO_API_RACE_MORE_THAN_ONE_RACE
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_OTHER_RACE
      mapped_race_ethnicity[:race] = Race::RACE_UNKNOWN_OR_NOT_REPORTED
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    when HealthPro::HEALTH_PRO_API_RACE_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER
      mapped_race_ethnicity[:race] = Race::RACE_NATIVE_HAWAIIAN_OTHER_PACIFIC_ISLANDER
      mapped_race_ethnicity[:ethnicity] = Patient::ETHNICITY_UNKNOWN_OR_NOT_REPORTED
    end
    mapped_race_ethnicity
  end

  # 1= Northwestern Memorial Hospital Galter Pavilion, 201 E Huron St, Chicago, IL (Downtown) |
  # 2= Northwestern Medicine Delnor Hospital, 302 Randall Rd, Geneva, IL (West Region) |
  # 3= Northwestern Medicine Primary Care, 870 N. Milwaukee Rd, Vernon Hills, IL (North Region)|
  # 4= No preference

  def map_paired_site
    site_preference = {}
    case self.paired_site
    when HealthPro::PAIRED_SITE_NEAR_NORTH_NW_FEINBERG_GALTER
      site_preference['site_preference___1'] = '1'
      site_preference['site_preference___2'] = '0'
      site_preference['site_preference___3'] = '0'
      site_preference['site_preference___4'] = '0'
    when HealthPro::PAIRED_SITE_DELNOR_HOSPITAL
      site_preference['site_preference___1'] = '0'
      site_preference['site_preference___2'] = '1'
      site_preference['site_preference___3'] = '0'
      site_preference['site_preference___4'] = '0'
    else
      site_preference['site_preference___1'] = '0'
      site_preference['site_preference___2'] = '0'
      site_preference['site_preference___3'] = '0'
      site_preference['site_preference___4'] = '1'
    end
    site_preference
  end

  def deceased
    if health_pro.present?
      health_pro.deceased
    end
  end

  def cope_feb_ppi_survey_complete_y
    if health_pro.present?
      health_pro.cope_feb_ppi_survey_complete
    end
  end

  def cope_feb_ppi_survey_completion_date_d
    if health_pro.present?
      health_pro.cope_feb_ppi_survey_completion_date
    end
  end

  def core_participant_minus_pm_date_d
    if health_pro.present?
      health_pro.core_participant_minus_pm_date
    end
  end

  def summer_minute_ppi_survey_complete_y
    if health_pro.present?
      health_pro.summer_minute_ppi_survey_complete
    end
  end

  def summer_minute_ppi_survey_completion_date_d
    if health_pro.present?
      health_pro.summer_minute_ppi_survey_completion_date
    end
  end

  def fall_minute_ppi_survey_complete_y
    if health_pro.present?
      health_pro.fall_minute_ppi_survey_complete
    end
  end

  def fall_minute_ppi_survey_completion_date_d
    if health_pro.present?
      health_pro.fall_minute_ppi_survey_completion_date
    end
  end

  def personal_and_family_hx_ppi_survey_complete_y
    if health_pro.present?
      health_pro.personal_and_family_hx_ppi_survey_complete
    end
  end

  def personal_and_family_hx_ppi_survey_completion_date_d
    if health_pro.present?
      health_pro.personal_and_family_hx_ppi_survey_completion_date
    end
  end

  def sdoh_ppi_survey_complete_y
    if health_pro.present?
      health_pro.sdoh_ppi_survey_complete
    end
  end

  def winter_minute_ppi_survey_complete_y
    if health_pro.present?
      health_pro.winter_minute_ppi_survey_complete
    end
  end

  def winter_minute_ppi_survey_completion_date_d
    if health_pro.present?
      health_pro.winter_minute_ppi_survey_completion_date
    end
  end

  def digital_health_status_fitbit_complete_y
    if health_pro.present?
      if digital_health_consent.present?
        if digital_health_consent['fitbit']
          case digital_health_consent['fitbit']['status']
          when 'NO'
            '0'
          when 'YES'
            '1'
          else
            nil
          end
        end
      end
    end
  end

  def digital_health_status_fitbit_completion_date_d
    if health_pro.present?
      if digital_health_consent.present?
        if digital_health_consent['fitbit']
          if digital_health_consent['fitbit']['authoredTime'].present?
            Date.parse(digital_health_consent['fitbit']['authoredTime'])
          end
        end
      end
    end
  end

  def digital_health_status_apple_health_kit_complete_y
    if health_pro.present?
      if digital_health_consent.present?
        if digital_health_consent['fitbit']
          case digital_health_consent['appleHealthKit']['status']
          when 'NO'
            '0'
          when 'YES'
            '1'
          else
            nil
          end
        end
      end
    end
  end

  def digital_health_status_apple_health_kit_completion_date_d
    if health_pro.present?
      if digital_health_consent.present?
        if digital_health_consent['fitbit']
          if digital_health_consent['fitbit']['authoredTime'].present?
            Date.parse(digital_health_consent['appleHealthKit']['authoredTime'])
          end
        end
      end
    end
  end

  def digital_health_status_apple_health_ehr_complete_y
    if health_pro.present?
      if digital_health_consent.present?
        if digital_health_consent['fitbit']
          case digital_health_consent['appleEHR']['status']
          when 'NO'
            '0'
          when 'YES'
            '1'
          else
            nil
          end
        end
      end
    end
  end

  def digital_health_status_apple_health_ehr_completion_date_d
    if health_pro.present?
      if digital_health_consent.present?
        if digital_health_consent['fitbit']
          if digital_health_consent['fitbit']['authoredTime'].present?
            Date.parse(digital_health_consent['appleEHR']['authoredTime'])
          end
        end
      end
    end
  end

  private
    def health_pro
      @health_pro ||= HealthPro.where(batch_health_pro_id: last_batch_health_pro_id, pmi_id: self.pmi_id).first
    end

    def digital_health_consent
      @digital_health_consent ||= JSON.parse(health_pro.digital_health_consent.gsub('=>', ':'))
    end

    def last_batch_health_pro_id
      last_batch_health_pro_id = HealthPro.where(pmi_id: self.pmi_id).maximum(:batch_health_pro_id)
    end

    def set_defaults
      if self.new_record? &&
        if self.registration_status.blank?
          self.registration_status = Patient::REGISTRATION_STATUS_UNMATCHED
        end
        uuid = UUID.new
        self.uuid = uuid.generate
      end
    end

    def save_default_patient_features
      PatientFeature::FEATURES.each do |feature|
        self.patient_features.build(feature: feature, enabled: false)
      end
      save!
    end
end