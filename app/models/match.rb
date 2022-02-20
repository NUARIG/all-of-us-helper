class Match <  ApplicationRecord
  has_paper_trail
  belongs_to :health_pro
  belongs_to :patient
  STATUS_PENDING        = 'pending'
  STATUS_ACCEPTED       = 'accepted'
  STATUS_DECLINED       = 'declined'
  STATUSES = [STATUS_PENDING, STATUS_ACCEPTED, STATUS_DECLINED]
  after_initialize :set_defaults

  validates_presence_of :patient_id

  scope :by_status, ->(status) do
    if status.present?
     where(status: status)
    end
  end

  def decline!(redcap_api)
    declined = nil
    begin
      Match.transaction do
        redcap_decline = redcap_api.decline(patient.record_id)
        raise "Error declining record_id  #{health_pro.pmi_id} to record_id #{patient.record_id}." if redcap_decline[:error].present?
        self.status = Match::STATUS_DECLINED
        save!
        if !health_pro.pending_matches?
          health_pro.status = HealthPro::STATUS_DECLINED
          health_pro.save!
        end
      end
      declined = true
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      declined = false
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
    end
    declined
  end

  def accept!(redcap_api, match_params)
    accepted = nil
    begin
      self.status = Match::STATUS_ACCEPTED
      patient.pmi_id = health_pro.pmi_id
      patient.birth_date = Date.parse(health_pro.date_of_birth)
      patient.general_consent_status = health_pro.general_consent_status
      patient.general_consent_date = health_pro.general_consent_date
      patient.ehr_consent_status = health_pro.ehr_consent_status
      patient.ehr_consent_date = health_pro.ehr_consent_date
      patient.withdrawal_status = health_pro.withdrawal_status
      patient.withdrawal_date = health_pro.withdrawal_date
      patient.biospecimens_location = health_pro.biospecimens_location
      patient.participant_status = health_pro.participant_status
      patient.paired_site = health_pro.paired_site
      patient.paired_organization = health_pro.paired_organization
      patient.physical_measurements_completion_date = health_pro.physical_measurements_completion_date
      patient.health_pro_email = health_pro.email
      patient.health_pro_phone = health_pro.phone
      patient.health_pro_login_phone = health_pro.login_phone
      patient.genomic_consent_status = health_pro.consent_for_genomics_ror
      patient.genomic_consent_status_date = health_pro.consent_for_genomics_ror_date
      patient.questionnaire_on_cope_may = health_pro.questionnaire_on_cope_may
      patient.questionnaire_on_cope_may_time = health_pro.questionnaire_on_cope_may_time
      patient.questionnaire_on_cope_june = health_pro.questionnaire_on_cope_june
      patient.questionnaire_on_cope_june_time = health_pro.questionnaire_on_cope_june_time
      patient.questionnaire_on_cope_july = health_pro.questionnaire_on_cope_july
      patient.questionnaire_on_cope_july_authored = health_pro.questionnaire_on_cope_july_authored
      patient.core_participant_date = health_pro.core_participant_date
      patient.deactivation_status = health_pro.deactivation_status
      patient.deactivation_date = health_pro.deactivation_date
      patient.required_ppi_surveys_complete = health_pro.required_ppi_surveys_complete
      patient.completed_surveys = health_pro.completed_surveys
      patient.basics_ppi_survey_complete = health_pro.basics_ppi_survey_complete
      patient.basics_ppi_survey_completion_date = health_pro.basics_ppi_survey_completion_date
      patient.health_ppi_survey_complete = health_pro.health_ppi_survey_complete
      patient.health_ppi_survey_completion_date = health_pro.health_ppi_survey_completion_date
      patient.lifestyle_ppi_survey_complete = health_pro.lifestyle_ppi_survey_complete
      patient.lifestyle_ppi_survey_completion_date = health_pro.lifestyle_ppi_survey_completion_date
      patient.hist_ppi_survey_complete = health_pro.hist_ppi_survey_complete
      patient.hist_ppi_survey_completion_date = health_pro.hist_ppi_survey_completion_date
      patient.meds_ppi_survey_complete = health_pro.meds_ppi_survey_complete
      patient.meds_ppi_survey_completion_date = health_pro.meds_ppi_survey_completion_date
      patient.family_ppi_survey_complete = health_pro.family_ppi_survey_complete
      patient.family_ppi_survey_completion_date = health_pro.family_ppi_survey_completion_date
      patient.access_ppi_survey_complete = health_pro.access_ppi_survey_complete
      patient.access_ppi_survey_completion_date = health_pro.access_ppi_survey_completion_date
      patient.date_of_first_primary_consent = health_pro.date_of_first_primary_consent
      patient.date_of_first_ehr_consent = health_pro.date_of_first_ehr_consent

      if match_params[:empi_match_id].present?
        empi_match = EmpiMatch.find(match_params[:empi_match_id])
        patient.gender =  empi_match.gender
        patient.nmhc_mrn = empi_match.nmhc_mrn
        patient.ethnicity = empi_match.ethnicity if empi_match.ethnicity
        empi_match.empi_race_matches.each do |empi_race_match|
          patient.races << empi_race_match.race
        end
        patient.build_patient_empi_match(empi_match: empi_match)
      end

      patient.gender ||=  health_pro.sex_to_patient_gender
      health_pro.status = HealthPro::STATUS_MATCHED

      Match.transaction do
        redcap_match = redcap_api.match(patient.record_id, health_pro.pmi_id, health_pro.general_consent_status, health_pro.general_consent_date, health_pro.ehr_consent_status, health_pro.ehr_consent_date, health_pro.withdrawal_status, health_pro.withdrawal_date, health_pro.participant_status, health_pro.physical_measurements_completion_date, health_pro.paired_site, health_pro.paired_organization, health_pro.email, health_pro.phone, health_pro.login_phone, patient.genomic_consent_status, patient.genomic_consent_status_date, patient.core_participant_date,patient.deactivation_status, patient.deactivation_date, patient.required_ppi_surveys_complete, patient.completed_surveys, patient.basics_ppi_survey_complete, patient.basics_ppi_survey_completion_date, patient.health_ppi_survey_complete, patient.health_ppi_survey_completion_date, patient.lifestyle_ppi_survey_complete, patient.lifestyle_ppi_survey_completion_date, patient.hist_ppi_survey_complete, patient.hist_ppi_survey_completion_date, patient.meds_ppi_survey_complete, patient.meds_ppi_survey_completion_date, patient.family_ppi_survey_complete, patient.family_ppi_survey_completion_date, patient.access_ppi_survey_complete, patient.access_ppi_survey_completion_date, patient.questionnaire_on_cope_may, patient.questionnaire_on_cope_may_time, patient.questionnaire_on_cope_june, patient.questionnaire_on_cope_june_time, patient.questionnaire_on_cope_july, patient.questionnaire_on_cope_july_authored, patient.date_of_first_primary_consent, patient.date_of_first_ehr_consent, patient.health_pro_address1, patient.health_pro_address2, patient.health_pro_city, patient.health_pro_state, patient.health_pro_zip, patient.wq_program_update_status, patient.wq_program_update_date, patient.deceased, patient.cope_feb_ppi_survey_complete_y, patient.cope_feb_ppi_survey_completion_date_d, patient.core_participant_minus_pm_date_d, patient.summer_minute_ppi_survey_complete_y, patient.summer_minute_ppi_survey_completion_date_d, patient.fall_minute_ppi_survey_complete_y, patient.fall_minute_ppi_survey_completion_date_d, patient.personal_and_family_hx_ppi_survey_complete_y, patient.personal_and_family_hx_ppi_survey_completion_date_d, patient.sdoh_ppi_survey_complete_y, patient.sdoh_ppi_survey_completion_date_d, patient.winter_minute_ppi_survey_complete_y, patient.winter_minute_ppi_survey_completion_date_d, patient.digital_health_status_fitbit_complete_y, patient.digital_health_status_fitbit_completion_date_d, patient.digital_health_status_apple_health_kit_complete_y, patient.digital_health_status_apple_health_kit_completion_date_d, patient.digital_health_status_apple_health_ehr_complete_y, patient.digital_health_status_apple_health_ehr_completion_date_d)
        raise "Error assigning pmi_id #{health_pro.pmi_id} to record_id #{patient.record_id}." if redcap_match[:error].present?
        save!
        health_pro.save!
        patient.set_registration_status
        patient.save!
      end
      accepted = true
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      accepted = false
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
    end
    accepted
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

  def reject!
    self.status = Match::STATUS_REJECTED
    save!
  end

  private
    def set_defaults
      if self.new_record? && self.status.blank?
        self.status = Match::STATUS_PENDING
      end
    end
end
