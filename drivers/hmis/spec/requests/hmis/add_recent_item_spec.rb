###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:mutation) do
    <<~GRAPHQL
      mutation AddRecentItem($input: AddRecentItemInput!) {
        addRecentItem(input: $input) {
          id
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
  end

  def perform_mutation(item_id:, item_type:)
    post_graphql(input: { item_id: item_id, item_type: item_type }) { mutation }
  end

  describe 'adding a client' do
    let!(:client) { create :hmis_hud_client, data_source: ds1, user: u1 }

    it 'records a viewable client in recent items' do
      response, result = perform_mutation(item_id: client.id, item_type: 'Client')

      aggregate_failures do
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'addRecentItem', 'id')).to eq(hmis_user.id.to_s)
        expect(hmis_user.recent_item_links.find_by(item: client)).to be_present
      end
    end

    it 'rejects a client the user cannot view' do
      inaccessible_client = create :hmis_hud_client, data_source: ds1, user: u1
      create :hmis_hud_enrollment, data_source: ds1, project: p2, client: inaccessible_client, user: u1

      expect do
        expect_access_denied(perform_mutation(item_id: inaccessible_client.id, item_type: 'Client'))
      end.not_to change(hmis_user.recent_item_links, :count)
    end

    it 'rejects a non-existent client id' do
      expect_access_denied(perform_mutation(item_id: '99999', item_type: 'Client'))
    end
  end

  describe 'adding a project' do
    it 'records a viewable project in recent items' do
      response, result = perform_mutation(item_id: p1.id, item_type: 'Project')

      aggregate_failures do
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'addRecentItem', 'id')).to eq(hmis_user.id.to_s)
        expect(hmis_user.recent_item_links.find_by(item: p1)).to be_present
      end
    end

    it 'rejects a project the user cannot view' do
      expect do
        expect_access_denied(perform_mutation(item_id: p2.id, item_type: 'Project'))
      end.not_to change(hmis_user.recent_item_links, :count)
    end

    it 'rejects a non-existent project id' do
      expect_access_denied(perform_mutation(item_id: '99999', item_type: 'Project'))
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
