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
  
  describe '#locked?' do
    it 'is true when locked_until is in the future' do
      user = FactoryGirl.create :user, locked_until: 1.hour.from_now
      expect(user).to be_locked
    end

    it 'is false when locked_until is in the past' do
      user = FactoryGirl.create :user, locked_until: 1.hour.ago
      expect(user).to_not be_locked
    end

    it 'is false when locked_until is empty' do
      user = FactoryGirl.create :user, locked_until: nil
      expect(user).to_not be_locked
    end
  end

  describe '#max_failed_logins_reached?' do
    let(:max_failed_attempts) { 2 }

    subject { user.max_failed_logins_reached?(max_failed_attempts) }

    context 'when the user has no login attempts' do
      it { is_expected.to eq false }
    end

    context 'when the user has only successful logins' do
      it { is_expected.to eq false }
    end

    context 'when the feature is disabled' do
      let(:max_failed_attempts) { -1 }
      it { is_expected.to eq false }
    end

    context 'when the maxium value is invalid' do
      let(:max_failed_attempts) { nil }
      it { is_expected.to eq false }
    end

    context 'when the maximum of attempts is reached' do
      before { FactoryGirl.create_list :login_attempt, 2, successful: false, user: user }

      context 'in a row' do
        it { is_expected.to eq true }
      end

      context 'but the last attempt was successful' do
        before { FactoryGirl.create :login_attempt, successful: true, user: user }
        it { is_expected.to eq false }
      end

      context 'but a successful between' do
        before do
          FactoryGirl.create :login_attempt, successful: true, user: user
          FactoryGirl.create :login_attempt, successful: false, user: user
        end

        it { is_expected.to eq false }
      end
    end

    context 'when the user has less then the maximum failed attempts' do
      before { FactoryGirl.create :login_attempt, successful: false, user: user }
      it { is_expected.to eq false }
    end
  end

end
