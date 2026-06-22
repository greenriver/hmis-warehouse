###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/graphql_helpers'

RSpec.describe 'PickList USERS', type: :request do
  include GraphqlHelpers
  include LoginAndPermissionsSpecHelper

  let!(:ds1) { create(:hmis_primary_data_source) }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }

  let!(:active_user) { create(:hmis_user, first_name: 'Active', last_name: 'User') }
  let!(:inactive_user) { create(:hmis_user, first_name: 'Inactive', last_name: 'User', active: false) }
  let!(:deleted_user) { create(:hmis_user, first_name: 'Deleted', last_name: 'User').tap(&:destroy!) }

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!) {
        pickList(pickListType: $pickListType) {
          code
          label
          groupCode
          groupLabel
        }
      }
    GRAPHQL
  end

  before do
    hmis_login(user)
  end

  it 'returns no users without permission' do
    response, result = post_graphql(pick_list_type: 'USERS') { query }
    expect(response.status).to eq(200)
    expect(result.dig('data', 'pickList')).to be_empty
  end

  shared_examples 'returns users grouped by status' do
    it 'returns active, inactive, and deleted users grouped by status' do
      response, result = post_graphql(pick_list_type: 'USERS') { query }
      expect(response.status).to eq(200)

      options_by_code = result.dig('data', 'pickList').index_by { |option| option['code'] }
      expect(options_by_code[active_user.id.to_s]).to include(
        'label' => active_user.full_name,
        'groupCode' => 'Active Users',
        'groupLabel' => 'Active Users',
      )
      expect(options_by_code[inactive_user.id.to_s]).to include(
        'label' => inactive_user.full_name,
        'groupCode' => 'Inactive Users',
        'groupLabel' => 'Inactive Users',
      )
      expect(options_by_code[deleted_user.id.to_s]).to include(
        'label' => deleted_user.full_name,
        'groupCode' => 'Deleted Users',
        'groupLabel' => 'Deleted Users',
      )
    end
  end

  context 'with administrate config permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_administrate_config, :can_manage_forms, :can_configure_data_collection]) }
    it_behaves_like 'returns users grouped by status'
  end

  context 'with audit enrollments permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_audit_enrollments, :can_view_enrollment_details, :can_view_project]) }
    it_behaves_like 'returns users grouped by status'
  end

  context 'with audit clients permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_audit_clients]) }
    it_behaves_like 'returns users grouped by status'
  end

  context 'with merge clients permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_merge_clients, :can_view_clients]) }
    it_behaves_like 'returns users grouped by status'
  end
end
