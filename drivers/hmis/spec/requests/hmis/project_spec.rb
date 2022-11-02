require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let!(:o1) { create :hmis_hud_organization, data_source_id: ds1.id, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source_id: ds1.id, organization: o1, user: u1 }
  let!(:pc1) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'CO-500' }
  let!(:pc2) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'CO-503' }
  let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code, inventory_start_date: '2020-01-01' }
  let!(:i2) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc2.coc_code, inventory_start_date: '2022-01-01' }
  let!(:f1) { create :hmis_hud_funder, data_source_id: ds1.id, project: p1 }
  let!(:f2) { create :hmis_hud_funder, data_source_id: ds1.id, project: p1 }
  let(:access_group) { create :hmis_access_group }

  describe 'project query' do
    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
      access_group.add_viewable(p1.as_warehouse)
      access_group.add(hmis_user)
    end

    let(:query) do
      <<~GRAPHQL
        query GetProject($id: ID!) {
          project(id: $id) {
            id
            projectName
            projectType
            HMISParticipatingProject
            HOPWAMedAssistedLivingFac
            contactInformation
            continuumProject
            description
            housingType
            operatingEndDate
            operatingStartDate
            residentialAffiliation
            targetPopulation
            trackingMethod
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
            dateCreated
            dateUpdated
            dateDeleted
          }
        }
      GRAPHQL
    end

    it 'resolves funders, project cocs, and inventories' do
      response, result = post_graphql(id: p1.id) { query }

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
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
