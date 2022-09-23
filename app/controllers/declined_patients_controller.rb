class DeclinedPatientsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_health_pro, only: [:update]
  helper_method :sort_column, :sort_direction

  def index
    authorize HealthPro, :declined_patients_index?
    params[:page]||= 1
    params[:biospecimens_location]||= 'all'
    options = {}
    options[:sort_column] = sort_column
    options[:sort_direction] = sort_direction
    @declined_patients = HealthPro.declined.by_biospecimens_location(params[:biospecimens_location]).search_across_fields_declined(params[:search], options).paginate(per_page: 10, page: params[:page])
  end

  def update
    authorize @health_pro, :declined_patient_update?
    if @health_pro.undecline!
      flash[:success] = 'Patient was successfully undeclined.'
      redirect_to declined_patients_url()
    else
      flash[:alert] = 'Patient was not successfully undeclined.'
      render action: 'index'
    end
  end

  private
    def health_pro_params
      params.require(:health_pro).permit(:status)
    end

    def load_health_pro
      @health_pro = HealthPro.find(params[:id])
    end

    def sort_column
      [ 'pmi_id', 'first_name', 'email', 'last_name', 'paired_organization', 'paired_site', 'biospecimens_location'].include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
    end
end