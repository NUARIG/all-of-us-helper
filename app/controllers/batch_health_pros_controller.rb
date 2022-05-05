class BatchHealthProsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_batch_health_pro, only: [:show]
  helper_method :sort_column, :sort_direction

  def index
    authorize BatchHealthPro
    params[:page]||= 1
    params[:match_status]||= 'all'
    options = {}
    options[:sort_column] = sort_column
    options[:sort_direction] = sort_direction
    @pending_batch_health_pros = BatchHealthPro.order('created_at DESC').by_status(BatchHealthPro::STATUS_PENDING, BatchHealthPro::STATUS_READY).by_match_status(params[:match_status]).paginate(per_page: 10, page: params[:page])
    @expired_batch_health_pros = BatchHealthPro.order('created_at DESC').by_status(BatchHealthPro::STATUS_EXPIRED).paginate(per_page: 10, page: params[:page])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    authorize BatchHealthPro
    @batch_health_pro = BatchHealthPro.new()
  end

  def create
    authorize BatchHealthPro

    add_file_uload('health_pro_file')

    BatchHealthPro.expire

    @batch_health_pro = BatchHealthPro.new(batch_health_pro_params)
    @batch_health_pro.created_user = current_user.username

    remove_file_uload('health_pro_file')

    if @batch_health_pro.save
      Delayed::Job.enqueue ProcessBatchHealthProJob.new(@batch_health_pro.id)
      flash[:success] = 'You have successfully uploaded Health Pro file.'
      redirect_to batch_health_pros_url() and return
    else
      flash.now[:alert] = 'Failed to upload Health Pro file.'
      render action: 'new'
    end
  end

  def show
    authorize BatchHealthPro
    params[:page]||= 1
    params[:status]||= HealthPro::STATUS_MATCHABLE
    params[:paired_organization]||= 'all'
    params[:paired_site]||= 'all'

    options = {}
    options[:sort_column] = sort_column
    options[:sort_direction] = sort_direction

    @unmatched_patients = Patient.not_deleted.by_registration_status(Patient::REGISTRATION_STATUS_UNMATCHED).map { |patient| ["#{patient.full_name} | Email: #{patient.email} | Phone: #{patient.phone_1} | Record ID: #{patient.record_id}", patient.id] }
    @health_pros = @batch_health_pro.health_pros.search_across_fields(params[:search], options).by_status(params[:status]).by_paired_organization(params[:paired_organization]).by_paired_site(params[:paired_site]).paginate(per_page: 10, page: params[:page])
  end

  private
    def batch_health_pro_params
      params.require(:batch_health_pro).permit(:id, :health_pro_file, :health_pro_file_cache)
    end

    def add_file_uload(file)
      if !params[:batch_health_pro]["#{file}_cache".to_sym].blank? && params[:batch_health_pro][file.to_sym].blank?
        params[:batch_health_pro][file.to_sym] = params[:batch_health_pro]["#{file}_cache".to_sym]
      end
    end

    def remove_file_uload(file)
      if params[:batch_health_pro]["#{file}_cache".to_sym].blank? && params[:batch_health_pro][file.to_sym].blank?
        @batch_health_pro[file.to_sym] = nil
      end
    end

    def load_batch_health_pro
      @batch_health_pro = BatchHealthPro.find(params[:id])
    end

    def sort_column
      ['created_at', 'status', 'pmi_id', 'first_name', 'last_name', 'sex', 'date_of_birth'].include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
    end
end