###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  let!(:ds1) { create :hmis_data_source }

  # current user
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let!(:access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_project])
  end

  # other HMIS user
  let!(:other_hmis_user) do
    hmis_user2 = create(:user).related_hmis_user(ds1)
    # put them in an HMIS user group
    create_access_control(hmis_user2, ds1)
    hmis_user2
  end

  # other warehouse-only user
  let(:other_warehouse_user) { create(:user) }

  before(:each) do
    hmis_login(user)
  end

  describe 'users query' do
    let(:query) do
      <<~GRAPHQL
        query GetUsers {
          applicationUsers {
            nodesCount
            nodes {
              id
            }
          }
        }
      GRAPHQL
    end

    it 'fails if current user lacks access' do
      response, = post_graphql { query }
      expect(response.status).to eq(500)
    end

    it 'succeeds if current user has audit permission' do
      add_permissions(access_control, :can_audit_users)
      response, = post_graphql { query }
      expect(response.status).to eq(200)
    end

    it 'succeeds if current user has impersonation permission' do
      add_permissions(access_control, :can_impersonate_users)
      response, = post_graphql { query }
      expect(response.status).to eq(200)
    end

    it 'does not resolve Warehouse-only users' do
      add_permissions(access_control, :can_audit_users)
      response, result = post_graphql { query }
      expect(response.status).to eq(200)

      returned_user_ids = result.dig('data', 'applicationUsers', 'nodes').map { |e| e['id'] }
      expect(returned_user_ids).to contain_exactly(user.id.to_s, other_hmis_user.id.to_s)
    end
  end

  describe 'user lookup' do
    let(:query) do
      <<~GRAPHQL
        query UserLookup($id: ID!) {
          user(id: $id) {
            id
            name
          }
        }
      GRAPHQL
    end

    it 'allows self lookup' do
      response, = post_graphql(id: user.id) { query }
      expect(response.status).to eq(200)
    end

    it 'fails if looking up another user if user lacks access' do
      response, = post_graphql(id: other_hmis_user.id) { query }
      expect(response.status).to eq(500)
    end

    it 'succeeds if current user has some user permission' do
      add_permissions(access_control, :can_audit_users)
      response, = post_graphql(id: other_hmis_user.id) { query }
      expect(response.status).to eq(200)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
