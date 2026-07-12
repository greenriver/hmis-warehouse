###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::UsersController, type: :request do
  include_context 'hmis base setup'

  describe 'GET /hmis/user.json' do
    context 'when authenticated' do
      before do
        hmis_login(user)
        get hmis_user_path
      end

      it 'includes a primaryIdp key (nil under Devise, since there is no connector)' do
        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed).to have_key('primaryIdp')
        expect(parsed['primaryIdp']).to be_nil
      end

      it 'includes the rest of the current-user payload' do
        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed['id']).to eq(hmis_user.id.to_s)
        expect(parsed['name']).to eq(hmis_user.name)
        expect(parsed['email']).to eq(hmis_user.email)
        expect(parsed['phone']).to eq(hmis_user.phone)
        expect(parsed['sessionDuration']).to eq(Devise.timeout_in.in_seconds)
        expect(parsed['impersonating']).to eq(false)
      end
    end

    context 'when not authenticated' do
      it 'is reachable without authentication (skip_before_action), and omits primaryIdp' do
        get hmis_user_path

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed).not_to have_key('primaryIdp')
      end
    end
  end
end
