class ApplicationController < ActionController::API
  include ActionController::Helpers
  helper_method :current_user, :logged_in?
  before_action :set_vars, :set_format

  private

  def set_vars
    @status = "ok"
    @error  = nil
  end
  
  def set_format
    request.format = 'json'
    if request.path_info.include? "coupons/apply"
      request.format = 'html'
    else
      request.format = 'json'
    end

  end

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find(session[:user_id])
  end

  def logged_in?
    if !session[:user_id]
     @status = "error"
      @error = "login needed!"
      return false
    end

    return true
  end
end
