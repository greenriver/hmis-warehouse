require 'rails_helper'

RSpec.describe OmniauthUserProvisioner, type: :model do
  include ActiveJob::TestHelper

  let(:email) { 'TEST@EXAMPLE.COM' }
  let(:auth) do
    OmniAuth::AuthHash.new(
      'provider' => 'wh_okta',
      'uid' => '1234',
      'info' => {
        'email' => email,
        'first_name' => 'Joe',
        'last_name' => 'Tester',
      },
      'extra' => {
        'raw_info' => {},
      },
      'credentials' => {},
    )
  end

  describe 'with no existing account' do
    it 'creates the account' do
      expect {
        OmniauthUserProvisioner.new.perform(auth: auth, user_scope: User)
        perform_enqueued_jobs
      }
        .to change(User, :count).by(1)
        .and change(OauthIdentity, :count).by(1)
    end
  end

  describe 'with an existing account with matching email' do
    let(:user) { create(:user, email: email.downcase) }
    it 'updates the matching user and normalizes the email' do
      expect {
        OmniauthUserProvisioner.new.perform(auth: auth, user_scope: User)
        perform_enqueued_jobs
        user.reload
      }
        .to not_change(User, :count)
        .and change(OauthIdentity.where(user:user), :count).by(1)
        .and change(ActionMailer::Base.deliveries, :last)
        .and not_change(user, :email)
        .and change(user, :first_name).to(auth.info['first_name'])
        .and change(user, :last_name).to(auth.info['last_name'])
        receive(:event_added).once
    end
  end
end
