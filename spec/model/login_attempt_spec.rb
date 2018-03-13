require 'spec_helper'

describe CASino::LoginAttempt do
  subject { described_class.new user_agent: 'TestBrowser' }

  it_behaves_like 'has browser info'

  describe '#failed?' do
    it 'is true when it is not successful' do
      login_attempt = FactoryGirl.create :login_attempt, successful: false
      expect(login_attempt).to be_failed
    end

    it 'is false when it is successful' do
      login_attempt = FactoryGirl.create :login_attempt, successful: true
      expect(login_attempt).to_not be_failed
    end
  end
end
