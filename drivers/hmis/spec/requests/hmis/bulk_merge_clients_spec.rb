###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'BulkMergeClients', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation BulkMergeClients($input: BulkMergeClientsInput!) {
        bulkMergeClients(input: $input) {
          success
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_merge_clients]) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:c2) { create :hmis_hud_client, data_source: ds1 }
  let!(:c3) { create :hmis_hud_client, data_source: ds1 }
  let!(:c4) { create :hmis_hud_client, data_source: ds1 }

  before(:each) do
    hmis_login(user)
    allow(Hmis::MergeClientsJob).to receive(:perform_now) # mock the job's internals, they are tested elsewhere
  end

  it 'returns success for multiple merge operations' do
    input = {
      input: [
        { client_ids: [c1.id, c2.id] },
        { client_ids: [c3.id, c4.id] },
      ],
    }

    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200)
    expect(result.dig('data', 'bulkMergeClients', 'success')).to eq(true)
    expect(result.dig('data', 'bulkMergeClients', 'errors')).to be_empty

    expect(Hmis::MergeClientsJob).to have_received(:perform_now).twice
  end

  describe 'permissions' do
    it 'fails if user lacks can_merge_clients permission' do
      remove_permissions(access_control, :can_merge_clients)
      input = { input: [{ client_ids: [c1.id, c2.id] }] }

      expect_access_denied post_graphql(input: input) { mutation }
      expect(Hmis::MergeClientsJob).not_to have_received(:perform_now)
    end

    it 'fails if user lacks prerequisite can_view_clients permission' do
      remove_permissions(access_control, :can_view_clients)
      input = { input: [{ client_ids: [c1.id, c2.id] }] }

      expect_access_denied post_graphql(input: input) { mutation }
      expect(Hmis::MergeClientsJob).not_to have_received(:perform_now)
    end
  end

  describe 'error handling' do
    it 'fails if a client is not found' do
      input = { input: [{ client_ids: [c1.id, '999999'] }] }

      expect_gql_error post_graphql(input: input) { mutation }, message: 'not found'
      expect(Hmis::MergeClientsJob).not_to have_received(:perform_now)
    end

    it 'fails if a client is not viewable by the user' do
      other_ds = create(:hmis_data_source)
      other_client = create(:hmis_hud_client, data_source: other_ds)

      input = { input: [{ client_ids: [c1.id, other_client.id] }] }

      expect_gql_error post_graphql(input: input) { mutation }, message: 'not found'
      expect(Hmis::MergeClientsJob).not_to have_received(:perform_now)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
