###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let(:u1) { create :hmis_hud_user, data_source: ds1 }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500' }
  let!(:pc2) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-503' }
  let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code, inventory_start_date: '2020-01-01' }
  let!(:i2) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc2.coc_code, inventory_start_date: '2022-01-01' }
  let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1 }
  let!(:f2) { create :hmis_hud_funder, data_source: ds1, project: p1 }
  let!(:referral_request) do
    create(:hmis_external_api_ac_hmis_referral_request, project: p1)
  end

  describe 'project query' do
    before(:each) do
      hmis_login(user)
    end

    let(:query) do
      <<~GRAPHQL
        query GetProject($id: ID!) {
          project(id: $id) {
            #{scalar_fields(Types::HmisSchema::Project)}
            inventories(limit: 1, offset: 1, sortOrder: START_DATE) {
              nodesCount
              nodes {
                id
              }
            }
            projectCocs(limit: 10, offset: 0) {
              nodesCount
              nodes {
                id
              }
            }
            funders {
              nodesCount
              nodes {
                id
              }
            }
            organization {
              id
              organizationName
            }
            access {
              #{scalar_fields(Types::HmisSchema::Project.fields['access'])}
            }
            referralRequests {
              nodes  {
                #{scalar_fields(Types::HmisSchema::ReferralRequest)}
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves funders, project cocs, referral requests, and inventories' do
      response, result = post_graphql(id: p1.id) { query }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'project')
        expect(record['id']).to be_present
        to_id = proc { |x| x['id'].to_i }
        expect(record.dig('inventories', 'nodesCount').to_i).to eq(2)
        expect(record.dig('inventories', 'nodes').map(&to_id)).to contain_exactly(i1.id)
        expect(record.dig('projectCocs', 'nodesCount').to_i).to eq(2)
        expect(record.dig('projectCocs', 'nodes').map(&to_id)).to contain_exactly(pc1.id, pc2.id)
        expect(record.dig('funders', 'nodesCount').to_i).to eq(2)
        expect(record.dig('funders', 'nodes').map(&to_id)).to contain_exactly(f1.id, f2.id)
        expect(record.dig('organization', 'id').to_i).to eq(o1.id)
        expect(record.dig('referralRequests', 'nodes', 0, 'id')).to eq(referral_request.id&.to_s)
      end
    end

    it 'handles permissions correctly' do
      hmis_user.access_controls.first.role.update(can_delete_project: false)
      _res, result = post_graphql(id: p1.id) { query }
      expect(result.dig('data', 'project', 'access')).to include('canDeleteProject' => false)

      hmis_user.access_controls.first.role.update(can_delete_project: true)
      _res, result = post_graphql(id: p1.id) { query }
      expect(result.dig('data', 'project', 'access')).to include('canDeleteProject' => true)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
