class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end

  before_action :configure_permitted_parameters, if: :devise_controller?

  def authenticate_user!
    store_location_for(:user, request.original_url)
    if !user_signed_in?
      flash[:alert] = 'You need to sign in or sign up before continuing.'
      redirect_to new_user_session_url
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
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
end
