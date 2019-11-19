class CASino::LoginAttemptsController < CASino::ApplicationController
  include CASino::SessionsHelper

  before_action :ensure_signed_in, only: [:index]

  def index
    @login_attempts = CASino::LoginAttempt.by_user_id_and_created_at(descending: true).key([current_user.id, ""]).page(params[:page]).per(10)
  end
end
