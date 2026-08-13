###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::SessionKeepalivesController, type: :request do
  include_context 'hmis base setup'

  before { hmis_login(user) }

  describe 'GET /hmis/session_keepalive' do
    it 'refreshes the session, matching the frontend\'s plain credentialed GET' do
      get hmis_session_keepalive_path

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('success' => true)
    end
  end

  describe 'POST /hmis/session_keepalive' do
    it 'still works for any caller still using the old verb' do
      post hmis_session_keepalive_path

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('success' => true)
    end
  end
end
