# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ceMatchClientFields query', type: :request do
  include_context 'hmis base setup'

  before { allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true) }

  let(:query) do
    <<~GRAPHQL
      query GetCeMatchClientFields {
        ceMatchClientFields {
          key
          label
          itemType
          repeats
          expressionField
          formDefinitionIdentifier
          pickListReference
          pickListOptions {
            code
            label
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_administrate_coordinated_entry]) }

  before(:each) { hmis_login(user) }

  def query_client_items
    response, result = post_graphql { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchClientFields')
  end

  it 'returns CE match field metadata for each supported client field' do
    items = query_client_items

    expect(items).to contain_exactly(
      hash_including('key' => 'current_age', 'itemType' => 'INTEGER', 'expressionField' => 'current_age', 'formDefinitionIdentifier' => nil),
      hash_including(
        'key' => 'veteran_status',
        'itemType' => 'CHOICE',
        'expressionField' => 'veteran_status',
        'formDefinitionIdentifier' => nil,
        'pickListReference' => 'NoYesReasonsForMissingData',
        'pickListOptions' => [],
      ),
      hash_including('key' => 'days_since_last_exit', 'itemType' => 'INTEGER', 'expressionField' => 'days_since_last_exit', 'formDefinitionIdentifier' => nil),
    )
  end

  context 'without can_administrate_config permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_coordinated_entry) }

    it 'returns an error' do
      expect_gql_error(post_graphql { query }, message: 'access denied')
    end
  end
end
