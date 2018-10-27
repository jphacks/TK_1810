class UsersController < ApplicationController
  def current
    return unless logged_in?
    @user = current_user
  end
end
