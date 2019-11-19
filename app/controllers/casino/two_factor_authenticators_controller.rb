require 'rotp'

class CASino::TwoFactorAuthenticatorsController < CASino::ApplicationController
  include CASino::SessionsHelper
  include CASino::TwoFactorAuthenticatorsHelper
  include CASino::TwoFactorAuthenticatorProcessor

  before_action :ensure_signed_in

  def new
    @two_factor_authenticator = CASino::TwoFactorAuthenticator.create!(user_id: current_user.id, secret: ROTP::Base32.random_base32)
  end

  def create
    @two_factor_authenticator = CASino::TwoFactorAuthenticator.get(params[:id])
    @two_factor_authenticator = nil if(@two_factor_authenticator.user_id != current_user.id)
    validation_result = validate_one_time_password(params[:otp], @two_factor_authenticator)
    case
    when validation_result.success?
      CASino::TwoFactorAuthenticator.by_user_id_and_active.key([current_user.id, true]).each {|tfa| tfa.destroy}
      @two_factor_authenticator.update_attributes(active: true)
      flash[:notice] = I18n.t('two_factor_authenticators.successfully_activated')
      redirect_to sessions_path
    when validation_result.error_code == 'INVALID_OTP'
      flash.now[:error] = I18n.t('two_factor_authenticators.invalid_one_time_password')
      render :new
    else
      flash[:error] = I18n.t('two_factor_authenticators.invalid_two_factor_authenticator')
      redirect_to new_two_factor_authenticator_path
    end
  end

  def destroy
    authenticator = CASino::TwoFactorAuthenticator.get(params[:id])
    if(authenticator && authenticator.user_id == current_user.id)
      authenticator.destroy
      flash[:notice] = I18n.t('two_factor_authenticators.successfully_deleted')
    end
    redirect_to sessions_path
  end
end
