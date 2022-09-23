require 'redcap_api'
require 'study_tracker_api'
class PatientsController < ApplicationController
  PATIENT_CONTROLLER_SHOW_REDCAP_ERROR = 'Failed to communicate with REDCap.'
  before_action :authenticate_user!
  before_action :load_patient, only: [:show, :register, :update]
  helper_method :sort_column, :sort_direction

  def record_id
    authorize Patient
    redcap_api = initialize_redcap_api
    @patient = Patient.not_deleted.where(record_id: params[:record_id]).first

    if @patient.blank?
      redcap_patient_response = redcap_api.patient(params[:record_id])
      if redcap_patient_response[:error].present?
        flash[:alert] = PATIENT_CONTROLLER_SHOW_REDCAP_ERROR
        redirect_to root_url and return
      end

      @patient = Patient.create_or_update!(redcap_patient_response[:response].slice('record_id', 'first_name', 'last_name', 'email'))
    end

    redirect_to patient_url(@patient)
  end

  def index
    authorize Patient
    params[:page]||= 1
    params[:registration_status]||= 'all'
    options = {}
    options[:sort_column] = sort_column
    options[:sort_direction] = sort_direction
    @patients = Patient.by_paired_site(params[:paired_site]).not_deleted.search_across_fields(params[:search], options).by_registration_status(params[:registration_status]).paginate(per_page: 10, page: params[:page])
  end

  def create
    authorize Patient
    health_pro = HealthPro.find(patient_params[:health_pro_id])
    health_pro.status = HealthPro::STATUS_ADDED
    patient = Patient.new
    patient.first_name = health_pro.first_name
    patient.last_name = health_pro.last_name
    patient.email = health_pro.email
    patient.pmi_id = health_pro.pmi_id
    patient.gender = health_pro.sex_to_patient_gender
    patient.general_consent_status = health_pro.general_consent_status
    patient.general_consent_date = health_pro.general_consent_date
    patient.ehr_consent_status = health_pro.ehr_consent_status
    patient.ehr_consent_date = health_pro.ehr_consent_date
    patient.withdrawal_status = health_pro.withdrawal_status
    patient.withdrawal_date = health_pro.withdrawal_date
    patient.biospecimens_location = health_pro.biospecimens_location
    patient.birth_date = health_pro.date_of_birth
    patient.participant_status = health_pro.participant_status
    patient.paired_site = health_pro.paired_site
    patient.paired_organization = health_pro.paired_organization
    patient.physical_measurements_completion_date = health_pro.physical_measurements_completion_date
    patient.phone_1 = health_pro.phone
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

    if patient_params[:empi_match_id].present?
      empi_match = EmpiMatch.find(patient_params[:empi_match_id])
      patient.gender =  empi_match.gender
      patient.nmhc_mrn = empi_match.nmhc_mrn
      patient.ethnicity = empi_match.ethnicity if empi_match.ethnicity
      empi_match.empi_race_matches.each do |empi_race_match|
        patient.races << empi_race_match.race
      end
      patient.build_patient_empi_match(empi_match: empi_match)
    end

    match = Match.new
    match.health_pro = health_pro
    match.status = Match::STATUS_ACCEPTED
    site_preference = patient.map_paired_site
    begin
      Patient.transaction do
        redcap_api = initialize_redcap_api
        redcap_patient = redcap_api.create_patient(patient.first_name, patient.last_name, patient.email, patient.phone_1, health_pro.pmi_id, health_pro.general_consent_status, health_pro.general_consent_date, health_pro.ehr_consent_status, health_pro.ehr_consent_date, health_pro.withdrawal_status, health_pro.withdrawal_date, health_pro.participant_status, health_pro.physical_measurements_completion_date, health_pro.paired_site, health_pro.paired_organization, health_pro.email, health_pro.phone, health_pro.login_phone, patient.genomic_consent_status, patient.genomic_consent_status_date, patient.core_participant_date,patient.deactivation_status, patient.deactivation_date, patient.required_ppi_surveys_complete, patient.completed_surveys, patient.basics_ppi_survey_complete, patient.basics_ppi_survey_completion_date, patient.health_ppi_survey_complete, patient.health_ppi_survey_completion_date, patient.lifestyle_ppi_survey_complete, patient.lifestyle_ppi_survey_completion_date, patient.access_ppi_survey_complete, patient.access_ppi_survey_completion_date, patient.questionnaire_on_cope_may, patient.questionnaire_on_cope_may_time, patient.questionnaire_on_cope_june, patient.questionnaire_on_cope_june_time, patient.questionnaire_on_cope_july, patient.questionnaire_on_cope_july_authored, site_preference['site_preference___1'], site_preference['site_preference___2'], site_preference['site_preference___3'], site_preference['site_preference___4'], patient.date_of_first_primary_consent, patient.date_of_first_ehr_consent, patient.health_pro_address1, patient.health_pro_address2, patient.health_pro_city, patient.health_pro_state, patient.health_pro_zip, patient.wq_program_update_status, patient.wq_program_update_date, patient.deceased, patient.cope_feb_ppi_survey_complete_y, patient.cope_feb_ppi_survey_completion_date_d, patient.core_participant_minus_pm_date_d, patient.summer_minute_ppi_survey_complete_y, patient.summer_minute_ppi_survey_completion_date_d, patient.fall_minute_ppi_survey_complete_y, patient.fall_minute_ppi_survey_completion_date_d, patient.personal_and_family_hx_ppi_survey_complete_y, patient.personal_and_family_hx_ppi_survey_completion_date_d, patient.sdoh_ppi_survey_complete_y, patient.sdoh_ppi_survey_completion_date_d, patient.winter_minute_ppi_survey_complete_y, patient.winter_minute_ppi_survey_completion_date_d, patient.digital_health_status_fitbit_complete_y, patient.digital_health_status_fitbit_completion_date_d, patient.digital_health_status_apple_health_kit_complete_y, patient.digital_health_status_apple_health_kit_completion_date_d, patient.digital_health_status_apple_health_ehr_complete_y, patient.digital_health_status_apple_health_ehr_completion_date_d, patient.hist_ppi_survey_complete, patient.hist_ppi_survey_completion_date, patient.family_ppi_survey_complete, patient.family_ppi_survey_completion_date)

        raise "Error creating a patient pmi_id #{health_pro.pmi_id}." if redcap_patient[:error].present?
        record_id = redcap_patient[:response]
        patient.record_id = record_id
        patient.save!
        match.patient = patient
        health_pro.save!
        match.save!
        patient.set_registration_status
        patient.save!
      end
      flash[:success] = 'You have successfully added a patient to REDCap.'
    rescue Exception => e
      Rails.logger.info(e.class)
      Rails.logger.info(e.message)
      Rails.logger.info(e.backtrace.join("\n"))
      flash[:alert] = 'Failed to add a match.'
    end
  end

  def show
    authorize @patient
    @invitation_code_assignment = @patient.invitation_code_assignments.build
  end

  def update
    authorize @patient
    options = {}
    options[:proxy_user] = current_user.username
    error = nil
    @patient.attributes = patient_params
    if @patient.valid_demographics? && @patient.update_attributes(patient_params)
      if @patient.registered?
        study_tracker_api = initialize_study_tracker_api
        registraion_results = study_tracker_api.register(options, @patient)
        error = registraion_results[:error]
      end
    else
      error = 'Patient could not be updated.'
    end

    if error.nil?
      flash[:success] = 'You have successfully updated a patient.'
      redirect_to patient_url(@patient)
    else
      flash.now[:alert] = "Failed to update patient: #{error}."
      render action: 'show'
    end
  end

  def register
    authorize Patient
    options = {}
    options[:proxy_user] = current_user.username
    study_tracker_api = initialize_study_tracker_api
    registration_results = study_tracker_api.register(options, @patient)

    if registration_results[:error].present?
      flash[:alert] = "Failed to register the patient."
    else
      @patient.registration_status = Patient::REGISTRATION_STATUS_REGISTERED
      @patient.save!
      flash[:success] = 'You have successfully registered a patient.'
    end
    redirect_to patient_url(@patient)
  end

  private
    def patient_params
      params.require(:patient).permit(:record_id, :first_name, :last_name, :birth_date, :email, :gender, :ethnicity, :nmhc_mrn, :empi_match_id, :health_pro_id, { race_ids:[] }, patient_features_attributes: [:id, :feature, :enabled, :_destroy])
    end

    def load_patient
      @patient = Patient.not_deleted.find(params[:id])
    end

    def sort_column
      ['record_id', 'paired_site', 'pmi_id', 'first_name', 'email', 'last_name', 'registration_status', 'physical_measurements_completion_date'].include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
    end
end