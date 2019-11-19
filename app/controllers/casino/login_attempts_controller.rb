class CASino::LoginAttemptsController < CASino::ApplicationController
  include CASino::SessionsHelper

  before_action :ensure_signed_in, only: [:index]

  def index
    #@login_attempts = current_user.login_attempts.order(created_at: :desc)
    @login_attempts = CASino::LoginAttempt.by_user_id_and_created_at.startkey([current_user.id, ""]).endkey([current_user.id, Time.now]).descending.page(params[:page]).per(10)
  end
end
