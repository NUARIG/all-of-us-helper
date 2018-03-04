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
    @patient = Patient.where(record_id: params[:record_id]).first

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
    @patients = Patient.search_across_fields(params[:search], options).by_registration_status(params[:registration_status]).paginate(per_page: 10, page: params[:page])
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
    if @patient.update_attributes(patient_params)
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
      params.require(:patient).permit(:record_id, :first_name, :last_name, :email, :gender, :ethnicity, :nmhc_mrn, { race_ids:[] })
    end

    def load_patient
      @patient = Patient.find(params[:id])
    end

    def sort_column
      ['record_id', 'pmi_id', 'first_name', 'email', 'last_name', 'registration_status'].include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
    end
end