###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Proves the inactivity modal is driven by the real session deadline, not a hard-coded lifetime,
# under AUTH_METHOD=jwt, while leaving the Devise arm's existing behavior untouched (the invariant
# the sync-modal-with-real-expiry plan requires). Runs under whichever AUTH_METHOD the current CI
# process is using, branching assertions the same way spec/requests/idp/warehouse_jwt_wiring_spec.rb
# does.
RSpec.describe 'Inactive session modal wiring', type: :request do
  let(:user) { create :user }

  before { sign_in(user) }

  it 'reports a real future deadline via the X-session-expires-at header' do
    get edit_account_path

    expect(response.headers['X-session-expires-at'].to_i).to be > Time.current.to_i
  end

  if AuthMethod.jwt?
    it 'passes the JWT modal an absolute deadline instead of a lifetime' do
      get edit_account_path

      expect(response.body).to include("data-inactive-session-modal-auth-method-value='jwt'")
      expect(response.body).to match(/data-inactive-session-modal-session-expires-at-value='\d+'/)
      expect(response.body).not_to include('data-inactive-session-modal-session-lifetime-secs-value')
    end
  else
    it 'keeps the Devise modal on Devise.timeout_in (regression: must not use the JWT deadline path)' do
      get edit_account_path

      expect(response.body).to include("data-inactive-session-modal-auth-method-value='devise'")
      expect(response.body).to include(%(data-inactive-session-modal-session-lifetime-secs-value='#{Devise.timeout_in.in_seconds}'))
      expect(response.body).not_to include('data-inactive-session-modal-session-expires-at-value')
    end
  end
end
