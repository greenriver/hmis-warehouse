# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ceMatchClientItems query', type: :request do
  include_context 'hmis base setup'

  let(:query) do
    <<~GRAPHQL
      query GetCeMatchClientItems {
        ceMatchClientItems {
          linkId
          type
          text
          repeats
          pickListReference
          ceMatchExpressionField
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: :can_administrate_config) }

  before(:each) { hmis_login(user) }

  def query_client_items
    response, result = post_graphql { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'ceMatchClientItems')
  end

  it 'returns a FormItem for each supported client field' do
    items = query_client_items

    expect(items).to contain_exactly(
      hash_including('linkId' => 'current_age',         'type' => 'INTEGER', 'ceMatchExpressionField' => 'current_age'),
      hash_including('linkId' => 'veteran_status',      'type' => 'CHOICE',  'ceMatchExpressionField' => 'veteran_status',
                     'pickListReference' => 'NoYesReasonsForMissingData'),
      hash_including('linkId' => 'days_since_last_exit', 'type' => 'INTEGER', 'ceMatchExpressionField' => 'days_since_last_exit'),
    )
  end

  context 'without can_administrate_config permission' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_config) }

    it 'returns an error' do
      expect_gql_error(post_graphql { query }, message: 'access denied')
    end
  end
end
