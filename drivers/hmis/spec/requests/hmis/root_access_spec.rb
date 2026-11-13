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

  before(:each) do
    hmis_login(user)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:bulk_void_enabled?).and_return(true)
  end

  describe 'root access query' do
    let(:query) do
      <<~GRAPHQL
        query GetRootPermissions {
          access {
            id
            #{scalar_fields(Types::HmisSchema::RootQueryAccess)}
          }
        }
      GRAPHQL
    end

    # All boolean fields except deprecated ones
    def permission_fields
      Types::HmisSchema::RootQueryAccess.fields.keys - ['id', 'canAdministerHmis', 'canTransferEnrollments']
    end

    context 'with all HMIS permissions' do
      let!(:access_control) { create_access_control(hmis_user, ds1) }

      it 'resolves all HMIS-granted permissions to true' do
        response, result = post_graphql { query }

        aggregate_failures 'checking response' do
          expect(response.status).to eq(200)

          access = result.dig('data', 'access')
          expect(access['id']).to be_present

          (permission_fields - ['canEditUsersInWarehouse']).each do |field|
            expect(access[field]).to eq(true), "expected #{field} to be true"
          end
        end
      end
    end

    context 'with no HMIS permissions' do
      let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: Hmis::Role.permissions) }

      it 'resolves all permissions to false' do
        response, result = post_graphql { query }

        aggregate_failures 'checking response' do
          expect(response.status).to eq(200)

          access = result.dig('data', 'access')
          expect(access['id']).to be_present
          permission_fields.each do |field|
            expect(access[field]).to eq(false), "expected #{field} to be false"
          end
        end
      end
    end

    context 'with mixed permissions' do
      let!(:p2) { create :hmis_hud_project, data_source: ds1 }
      let!(:p1_access_control) { create_access_control(hmis_user, p1, without_permission: [:can_edit_clients, :can_edit_project_details]) }
      let!(:p2_access_control) { create_access_control(hmis_user, p2, without_permission: [:can_edit_clients]) }

      it 'resolves permissions based on effective access' do
        response, result = post_graphql { query }

        aggregate_failures 'checking response' do
          expect(response.status).to eq(200)

          access = result.dig('data', 'access')
          expect(access['id']).to be_present
          expect(access['canEditProjectDetails']).to eq(true) # allowed in p2
          expect(access['canEditClients']).to eq(false) # disallowed in all ACLs
          expect(access['canEditUsersInWarehouse']).to eq(false) # base setup doesn't enable warehouse perms
        end
      end
    end

    it 'minimizes n+1 queries' do
      create_access_control(hmis_user, ds1)

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
