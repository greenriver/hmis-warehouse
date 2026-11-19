###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/graphql_helpers'

RSpec.describe 'PickList OTHER_FUNDERS', type: :request do
  include GraphqlHelpers
  include LoginAndPermissionsSpecHelper

  let!(:ds1) { create(:hmis_primary_data_source) }
  let!(:ds2) { create(:hmis_data_source) }
  let!(:user) { create(:user) }
  let(:local_funder) { HudHelper.util.local_or_other_funding_source }

  let!(:included_funder) { create(:hmis_hud_funder, data_source: ds1, Funder: local_funder, OtherFunder: 'City Grant') }
  let!(:duplicate_funder) { create(:hmis_hud_funder, data_source: ds1, Funder: local_funder, OtherFunder: 'City Grant') }
  let!(:non_local_funder) { create(:hmis_hud_funder, data_source: ds1, Funder: 2, OtherFunder: 'Not Local') }
  let!(:other_data_source_funder) { create(:hmis_hud_funder, data_source: ds2, Funder: local_funder, OtherFunder: 'Other Data Source') }

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!) {
        pickList(pickListType: $pickListType) {
          code
          label
        }
      }
    GRAPHQL
  end

  before do
    hmis_login(user)
  end

  it 'lists unique OtherFunder names for local funders in the current data source when prepared statements are off' do
    # Development disables prepared statements when query log tags are on, so values are inlined into the SQL.
    response, result = Hmis::Hud::Funder.connection.unprepared_statement do
      post_graphql(pick_list_type: 'OTHER_FUNDERS') { query }
    end
    expect(response.status).to eq(200)
    expect(result['errors']).to be_nil
    expect(result.dig('data', 'pickList')).to contain_exactly({ 'code' => 'City Grant', 'label' => 'City Grant' })
  end
end
