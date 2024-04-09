###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
  let!(:cep1) { create :hmis_hud_ce_participation, data_source: ds1, project: p1 }
  let!(:hp1) { create :hmis_hud_hmis_participation, data_source: ds1, project: p1 }
  let!(:referral_request) do
    create(:hmis_external_api_ac_hmis_referral_request, project: p1)
  end

  # both WIP and non-WIP assessments on a non-WIP enrollment
  let!(:e1) { create(:hmis_hud_enrollment, project: p1, data_source: p1.data_source) }
  let!(:a1) { create(:hmis_custom_assessment, enrollment: e1, client: e1.client) }
  let!(:a2) { create(:hmis_wip_custom_assessment, enrollment: e1, client: e1.client) }

  # both WIP and non-WIP assessments on a WIP enrollment
  let!(:e2) { create(:hmis_hud_wip_enrollment, project: p1, data_source: p1.data_source) }
  let!(:a3) { create(:hmis_wip_custom_assessment, enrollment: e2, client: e2.client) }
  let!(:a4) { create(:hmis_custom_assessment, enrollment: e2, client: e2.client) }

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
            ceParticipations {
              nodesCount
              nodes {
                #{scalar_fields(Types::HmisSchema::CeParticipation)}
              }
            }
            hmisParticipations {
              nodesCount
              nodes {
                #{scalar_fields(Types::HmisSchema::HmisParticipation)}
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
        expect(record.dig('ceParticipations', 'nodes', 0, 'id')).to eq(cep1.id&.to_s)
        expect(record.dig('hmisParticipations', 'nodes', 0, 'id')).to eq(hp1.id&.to_s)
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

  describe 'project assessments query' do
    before(:each) do
      hmis_login(user)
    end

    let(:project_assessments_query) do
      <<~GRAPHQL
        query GetProjectAssessments(
          $id: ID!
          $limit: Int = 10
          $offset: Int = 0
        ) {
          project(id: $id) {
            assessments(
              limit: $limit
              offset: $offset
            ) {
              offset
              limit
              nodesCount
              nodes {
                id
                inProgress
                role
                definition {
                  title
                }
                enrollment {
                  entryDate
                  exitDate
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves both WIP and non-WIP assessments on the project' do
      response, result = post_graphql(id: p1.id) { project_assessments_query }
      expect(response.status).to eq 200
      records = result.dig('data', 'project', 'assessments', 'nodes')
      expect(records.size).to eq(4)
      expect(records.pluck('id')).to contain_exactly(a1.id.to_s, a2.id.to_s, a3.id.to_s, a4.id.to_s)
    end

    describe 'with many assessments' do
      before(:each) do
        40.times.map do
          c = create :hmis_hud_client_complete, data_source: ds1, user: u1
          e = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c, user: u1
          5.times.map do
            create :hmis_wip_custom_assessment, enrollment: e, client: c
            create :hmis_custom_assessment, enrollment: e, client: c
          end
        end
      end

      it 'resolves assessments in a reasonable amount of time' do
        expect do
          _response, result = post_graphql(id: p1.id) { project_assessments_query }
          expect(result.dig('data', 'project', 'assessments', 'nodesCount')).to eq 404
        end.to perform_under(200).ms
      end

      it 'minimizes n+1 queries' do
        expect do
          post_graphql(id: p1.id) { project_assessments_query }
        end.to make_database_queries(count: 10..30)
      end
    end

    it 'does not return any assessments when the user lacks permission' do
      remove_permissions(access_control, :can_view_enrollment_details)
      _response, result = post_graphql(id: p1.id) { project_assessments_query }
      expect(result.dig('data', 'project', 'assessments', 'nodesCount')).to eq 0
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
