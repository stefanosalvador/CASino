class CASino::SessionsController < CASino::ApplicationController
  include CASino::SessionsHelper
  include CASino::AuthenticationProcessor
  include CASino::TwoFactorAuthenticatorProcessor

  before_action :validate_login_ticket, only: [:create]
  before_action :ensure_service_allowed, only: [:new, :create]
  before_action :load_ticket_granting_ticket_from_parameter, only: [:validate_otp]
  before_action :ensure_signed_in, only: [:index, :destroy]

  def index
    @ticket_granting_tickets = CASino::TicketGrantingTicket.active_by_user(current_user)
    @two_factor_authenticators = CASino::TwoFactorAuthenticator.by_user_id_and_active.key([current_user.id, true]).all
    @login_attempts = CASino::LoginAttempt.by_user_id_and_created_at(descending: true).key([current_user.id, ""]).limit(5).all
  end

  def new
    tgt = current_ticket_granting_ticket
    return handle_signed_in(tgt) unless params[:renew].present? || tgt.nil?
    redirect_to(params[:service]) if params[:gateway].present? && params[:service].present?
  end

  def create
    return show_login_error I18n.t('login_credential_acceptor.user_is_locked') if user_locked?(params[:username])

    validation_result = validate_login_credentials(params[:username], params[:password])
    if validation_result
      sign_in(validation_result, long_term: params[:rememberMe], credentials_supplied: true)
    else
      handle_failed_login params[:username]
      show_login_error I18n.t('login_credential_acceptor.invalid_login_credentials')
    end
  end

  def destroy
    ticket = CASino::TicketGrantingTicket.get(params[:id])
    ticket.destroy if(ticket && ticket.user_id != current_user.id)
    redirect_to sessions_path
  end

  def destroy_others
    CASino::TicketGrantingTicket.by_user_id.key(current_user.id).each do |tgt|
      tgt.destroy if(tgt.nil? || tgt.id != current_ticket_granting_ticket.id)
    end
    redirect_to params[:service].present? ? params[:service] : sessions_path
  end

  def logout
    sign_out
    @url = params[:url]
    if params[:service].present? && service_allowed?(params[:service])
      redirect_to params[:service], status: :see_other
    end
  end

  def validate_otp
    validation_result = validate_one_time_password(params[:otp], @ticket_granting_ticket.user.active_two_factor_authenticator)
    return flash.now[:error] = I18n.t('validate_otp.invalid_otp') unless validation_result.success?
    @ticket_granting_ticket.update_attributes(awaiting_two_factor_authentication: false)
    set_tgt_cookie(@ticket_granting_ticket)
    handle_signed_in(@ticket_granting_ticket)
  end

  private

  def show_login_error(message)
    flash.now[:error] = message
    render :new, status: :forbidden
  end

  def validate_login_ticket
    unless CASino::LoginTicket.consume(params[:lt])
      show_login_error I18n.t('login_credential_acceptor.invalid_login_ticket')
    end
  end

  def ensure_service_allowed
    if params[:service].present? && !service_allowed?(params[:service])
      render 'service_not_allowed', status: :forbidden
    end
  end

  def load_ticket_granting_ticket_from_parameter
    @ticket_granting_ticket = find_valid_ticket_granting_ticket(params[:tgt], request.user_agent, ignore_two_factor: true)
    redirect_to login_path if @ticket_granting_ticket.nil?
  end
end
