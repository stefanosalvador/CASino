require 'spec_helper'

describe CASino::User do
  let(:user) {  FactoryBot.create :user }

  let!(:ticket_granting_ticket) { FactoryBot.create :ticket_granting_ticket, user: user }
  let!(:two_factor_authenticator) { FactoryBot.create :two_factor_authenticator, user: user }
  let!(:login_attempt) { FactoryBot.create :login_attempt, user: user }

  subject { user }

  describe '#destroy' do
    before(:each) do
      CASino::ServiceTicket::SingleSignOutNotifier.any_instance.stub(:notify).and_return(false)
    end

    it 'deletes depending ticket-granting-ticket' do
      lambda {
        user.destroy
      }.should change(CASino::TicketGrantingTicket, :count).by(-1)
    end

    it 'deletes depending two-factor-authenticator' do
      lambda {
        user.destroy
      }.should change(CASino::TwoFactorAuthenticator, :count).by(-1)
    end

    it 'deletes depending login-attempt' do
      lambda {
        user.destroy
      }.should change(CASino::LoginAttempt, :count).by(-1)
    end
  end
end
