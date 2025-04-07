###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
  end

  let!(:p2) { create :hmis_hud_project, data_source: ds1 }

  let!(:p1_access_control) { create_access_control(hmis_user, p1, without_permission: [:can_edit_clients, :can_edit_project_details]) }
  let!(:p2_access_control) { create_access_control(hmis_user, p2, without_permission: [:can_edit_clients]) }

  describe 'root access query' do
    let(:query) do
      <<~GRAPHQL
        query GetRootPermissions {
          access {
            id
            # Dynamically resolve all access fields
            #{scalar_fields(Types::HmisSchema::QueryType.fields['access'].type.of_type)}
          }
        }
      GRAPHQL
    end

    it 'resolves all permissions' do
      response, result = post_graphql { query }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200

        access = result.dig('data', 'access')
        expect(access['id']).to be_present
        expect(access['canEditProjectDetails']).to eq(true) # allowed in p1
        expect(access['canEditClients']).to eq(false) # disallowed in all ACLs
        expect(access['canEditUsersInWarehouse']).to eq(false) # base setup doesn't enable warehouse perms
      end
    end

    it 'minimizes n+1 queries' do
      expect do
        response, result = post_graphql { query }
        expect(response.status).to eq(200), result.inspect
      end.to make_database_queries(count: 5..15)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
