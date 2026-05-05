###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::ImpersonationsController, type: :request do
  let(:ds) { create :hmis_primary_data_source }
  let(:headers) do
    {
      'HOST' => ds.hmis,
    }
  end

  let(:user_group) { create(:hmis_user_group) }
  let(:admin_user) do
    user = create(:hmis_user, data_source: ds)
    create_access_control(user, ds, with_permission: [:can_impersonate_users], user_group: user_group)
    user
  end
  let(:regular_user) do
    create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) }
  end
  let(:target_user) do
    create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) }
  end

  describe 'POST /create' do
    context 'when user is authorized to impersonate' do
      before do
        hmis_login admin_user
        post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      end

      it 'was successful' do
        expect(response.status).to eq 200
        parsed = JSON.parse response.body
        expect(parsed['id']).to eq(target_user.id.to_s)
        expect(controller.current_hmis_user).to eq(target_user)
      end
    end

    context 'when user is not authorized to impersonate' do
      before do
        hmis_login regular_user
        post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is in another data source' do
      let!(:other_data_source) { create :hmis_data_source }
      let!(:other_data_source_user) { create :hmis_user }
      let!(:other_ds_access_control) { create_access_control(other_data_source_user, other_data_source) }

      it 'cannot impersonate a user from another data source' do
        hmis_login admin_user

        post hmis_impersonations_path, params: { user_id: other_data_source_user.id }, headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /destroy' do
    before do
      hmis_login admin_user
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      delete hmis_impersonations_path, headers: headers
    end

    it 'returns to original user' do
      expect(response.status).to eq 200
      parsed = JSON.parse response.body
      expect(parsed['id']).to eq(admin_user.id.to_s)
      expect(controller.current_hmis_user).to eq(admin_user)
    end
  end
end
