###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseCurrentUser, :devise_only, type: :controller do
  controller(ActionController::Base) do
    include DeviseCurrentUser

    def countdown
      render json: inactive_session_countdown_values
    end
  end

  before do
    routes.draw do
      get 'countdown' => 'anonymous#countdown'
    end
  end

  describe '#inactive_session_countdown_values' do
    it 'reports the Devise timeout as a session lifetime' do
      get :countdown

      expect(JSON.parse(response.body)).to eq('session_lifetime_secs_value' => Devise.timeout_in.in_seconds)
    end
  end

  describe '#user_session_expires_at' do
    let(:warden) { instance_double(Warden::Proxy) }

    before { allow(controller).to receive(:warden).and_return(warden) }

    def user_session_expires_at
      controller.send(:user_session_expires_at)
    end

    it 'measures the timeout from the last_request_at stored in the Warden session' do
      freeze_time do
        last_request_at = 10.minutes.ago.to_i
        allow(warden).to receive(:authenticated?).with(:user).and_return(true)
        allow(warden).to receive(:session).with(:user).and_return('last_request_at' => last_request_at)

        expect(user_session_expires_at).to eq(Time.zone.at(last_request_at) + Devise.timeout_in)
        expect(user_session_expires_at).to be < Time.current + Devise.timeout_in
      end
    end

    it 'returns nil when the Warden session has no last_request_at' do
      allow(warden).to receive(:authenticated?).with(:user).and_return(true)
      allow(warden).to receive(:session).with(:user).and_return({})

      expect(user_session_expires_at).to be_nil
    end

    it 'returns nil without reading the Warden session when no user is signed in' do
      allow(warden).to receive(:authenticated?).with(:user).and_return(false)
      allow(warden).to receive(:session)

      expect(user_session_expires_at).to be_nil
      expect(warden).not_to have_received(:session)
    end
  end
end
