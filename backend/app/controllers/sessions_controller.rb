class SessionsController < ApplicationController
  def create
    @user = User.find_or_create_from_auth(request.env['omniauth.auth'])
    session[:user_id] = @user.id
    @sid = request.cookies["_session_id"]
  end

  def destroy
    reset_session
  end
end
