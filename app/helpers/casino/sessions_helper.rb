require 'addressable/uri'

module CASino::SessionsHelper
  include CASino::TicketGrantingTicketProcessor
  include CASino::ServiceTicketProcessor

  def current_ticket_granting_ticket?(ticket_granting_ticket)
    ticket_granting_ticket.ticket == cookies[:tgt]
  end

  def current_ticket_granting_ticket
    return nil unless cookies[:tgt]
    return @current_ticket_granting_ticket unless @current_ticket_granting_ticket.nil?
    find_valid_ticket_granting_ticket(cookies[:tgt], request.user_agent).tap do |tgt|
      cookies.delete :tgt if tgt.nil?
      @current_ticket_granting_ticket = tgt
    end
  end

  def current_user
    tgt = current_ticket_granting_ticket
    return nil if tgt.nil?
    tgt.user
  end

  def current_authenticator_context
    CASino.config.authenticator_context_builder.call(params, request)
  end

  def ensure_signed_in
    redirect_to login_path unless signed_in?
  end

  def signed_in?
    !current_ticket_granting_ticket.nil?
  end

  def sign_in(authentication_result, options = {})
    tgt = acquire_ticket_granting_ticket(authentication_result, request.user_agent, request.remote_ip, options)
    create_login_attempt(tgt.user, true)
    set_tgt_cookie(tgt)
    handle_signed_in(tgt, options)
  end

  def set_tgt_cookie(tgt)
    cookies[:tgt] = { value: tgt.ticket }.tap do |cookie|
      if tgt.long_term?
        cookie[:expires] = CASino.config.ticket_granting_ticket[:lifetime_long_term].seconds.from_now
      end
    end
  end

  def sign_out
    remove_ticket_granting_ticket(cookies[:tgt], request.user_agent)
    cookies.delete :tgt
  end

  def user_locked?(username)
    result = CASino::User.by_username.key(username)


    # If we've never seen this user before, it can't be locked already.
    return false if result.count == 0

    # A user is only locked, if all its CASino::Users, from all providers, are locked.
    # Because it might be, that it is locked for one (e.g. legacy) provider, but not for another.
    # So it should still have the chance to login to said other provider.
    locks = 0
    result.each {|user| locks += 1 if(user.locked_until.nil? || user.locked_until <= Time.now)}
    return locks == 0
    #return result.where('locked_until IS NULL or locked_until <= :now', username: username, now: Time.now).empty?
  end

  def handle_failed_login(username)
    CASino::User.by_username.key(username).each do |user|
      create_login_attempt(user, false)
      prevent_brute_force(user)
    end
  end

  def create_login_attempt(user, successful)
    CASino::LoginAttempt.create! user_id: user.id,
                                 successful: successful,
                                 service: params[:service],
                                 user_ip: request.ip,
                                 user_agent: request.user_agent
  end

  private

  def handle_signed_in(tgt, options = {})
    if tgt.awaiting_two_factor_authentication?
      @ticket_granting_ticket = tgt
      render 'casino/sessions/validate_otp'
    else
      if params[:service].present?
        begin
          handle_signed_in_with_service(tgt, options)
          return
        rescue Addressable::URI::InvalidURIError => e
          Rails.logger.warn "Service #{params[:service]} not valid: #{e}"
        end
      end
      redirect_to sessions_path, status: :see_other
    end
  end

  def handle_signed_in_with_service(tgt, options)
    if service_allowed?(params[:service])
      url = acquire_service_ticket(tgt, params[:service], options).service_with_ticket_url
      redirect_to url, status: :see_other
    else
      @service = params[:service]
      render 'casino/sessions/service_not_allowed', status: 403
    end
  end

  def prevent_brute_force(user)
    return unless user.max_failed_logins_reached?(CASino.config.max_failed_login_attempts)
    lock_timeout_minutes = CASino.config.failed_login_lock_timeout.to_i.minutes
    user.update_attributes locked_until: lock_timeout_minutes.from_now
  end
end
