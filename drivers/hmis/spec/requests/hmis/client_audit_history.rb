###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_dob, :can_view_project, :can_view_enrollment_details])
  end
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:all) do
    @paper_trail_was = PaperTrail.enabled?
    PaperTrail.enabled = true
  end
  after(:all) do
    PaperTrail.enabled = @paper_trail_was
  end

  describe 'client with paper trail enabled' do
    before(:each) do
      hmis_login(user)
    end

    let(:query) do
      <<~GRAPHQL
        query GetClient($id: ID!) {
          client(id: $id) {
            id
            auditHistory(limit: 10, offset: 0) {
              nodes {
                id
                createdAt
                event
                objectChanges
                recordName
                recordId
                user {
                  id
                  name
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves audit history' do
      c1.update!(last_name: "Test#{Time.current.to_i}")
      response, result = post_graphql(id: c1.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result.inspect
        records = result.dig('data', 'client', 'auditHistory', 'nodes')
        expect(records.size).to be <= 1
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
