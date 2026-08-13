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
end
