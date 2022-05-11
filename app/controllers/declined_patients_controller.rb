require 'redcap_api'
class DeclinedPatientsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_health_pro, only: [:update]
  helper_method :sort_column, :sort_direction

  def index
    authorize HealthPro, :declined_patients_index?
    params[:page]||= 1
    options = {}
    options[:sort_column] = sort_column
    options[:sort_direction] = sort_direction
    @declined_patients = HalthPro.declined.search_across_fields_declined(params[:search], options).paginate(per_page: 10, page: params[:page])
  end

  def update
    authorize @health_pro, :declined_patient_update?
    if @health_pro.update_attributes(health_pro_params)
      flash[:success] = 'Patient was successfully undeclined.'
      redirect_to declined_patients_url()
    else
      flash[:alert] = 'Patient was not successfully undeclined.'
      render action: 'index'
    end
  end

  private
    def patient_params
      params.require(:patient).permit(:record_id, :first_name, :last_name, :birth_date, :email, :gender, :ethnicity, :nmhc_mrn, :empi_match_id, :health_pro_id, { race_ids:[] }, patient_features_attributes: [:id, :feature, :enabled, :_destroy])
    end

    def load_health_pro
      @patient = HealthPro.find(params[:id])
    end

    def sort_column
      [ 'pmi_id', 'first_name', 'email', 'last_name', 'paired_site'].include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
    end
end