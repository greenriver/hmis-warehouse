# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ceMatchClientFields query', type: :request do
  include_context 'hmis base setup'

  let(:query) do
    <<~GRAPHQL
      query GetCeMatchClientFields {
        ceMatchClientFields {
          key
          label
          itemType
          multiple
          expressionField
          pickListReference
          pickListOptions {
            code
            label
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_administrate_config, :can_manage_forms, :can_configure_data_collection]) }

  before(:each) { hmis_login(user) }

  def query_client_items
    response, result = post_graphql { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchClientFields')
  end

  it 'returns CE match field metadata for each supported client field' do
    items = query_client_items

    expect(items).to contain_exactly(
      hash_including('key' => 'current_age', 'itemType' => 'INTEGER', 'multiple' => false, 'expressionField' => 'current_age'),
      hash_including(
        'key' => 'veteran_status',
        'itemType' => 'CHOICE',
        'multiple' => false,
        'expressionField' => 'veteran_status',
        'pickListReference' => 'NoYesReasonsForMissingData',
        'pickListOptions' => nil,
      ),
      hash_including('key' => 'days_since_last_exit', 'itemType' => 'INTEGER', 'multiple' => false, 'expressionField' => 'days_since_last_exit'),
      hash_including('key' => 'open_enrollment_project_types', 'itemType' => 'CHOICE', 'multiple' => true, 'expressionField' => 'open_enrollment_project_types', 'pickListReference' => 'ProjectType', 'pickListOptions' => nil),
      hash_including('key' => 'open_enrollment_project_types_excluding_incomplete', 'itemType' => 'CHOICE', 'multiple' => true, 'expressionField' => 'open_enrollment_project_types_excluding_incomplete', 'pickListReference' => 'ProjectType', 'pickListOptions' => nil),
      hash_including('key' => 'open_referral_project_types', 'itemType' => 'CHOICE', 'multiple' => true, 'expressionField' => 'open_referral_project_types', 'pickListReference' => 'ProjectType', 'pickListOptions' => nil),
    )
  end

  context 'without can_administrate_config permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_config) }

    it 'returns an error' do
      expect_gql_error(post_graphql { query }, message: 'access denied')
    end
  end
end
