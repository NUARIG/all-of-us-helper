class ApplicationController < ActionController::Base
  UNAUTHORIZED_MESSAGE = "You are not authorized to perform this action."
  protect_from_forgery with: :exception
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end

  before_action :set_paper_trail_whodunnit
  before_action :configure_permitted_parameters, if: :devise_controller?

  def authenticate_user!
    store_location_for(:user, request.original_url)
    if !user_signed_in?
      flash[:alert] = 'You need to sign in or sign up before continuing.'
      redirect_to new_user_session_url
    end
    audit_action
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def initialize_redcap_api
    redcap_api = RedcapApi.initialize_redcap_api
  end

  def initialize_study_tracker_api
    study_tracker_api = StudyTrackerApi.new
  end

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_in) do |user_params|
        user_params.permit(:username, :email, :password)
      end

      devise_parameter_sanitizer.permit(:account_update) do |user_params|
        user_params.permit(:last_name, :first_name)
      end
    end

  private
    def after_sign_out_path_for(resource_or_scope)
      root_path
    end

    def user_not_authorized
      flash[:alert] = UNAUTHORIZED_MESSAGE
      redirect_to(request.referrer || root_path)
    end

    def audit_action
      if current_user
        AuditAction.create(user: current_user, controller: controller_name, action: request.path, browser: request.env['HTTP_USER_AGENT'], params: params.except(:utf8, :_method, :authenticity_token, :controller, :action))
      end
    end
end
