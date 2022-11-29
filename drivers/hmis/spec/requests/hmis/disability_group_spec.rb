require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:c1) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

  let(:date1) { 1.year.ago }
  let(:date2) { 1.month.ago }

  # disability group 1
  let!(:d1a) { create :hmis_disability, data_source: ds1, client: c1, user: u1, enrollment: e1, data_collection_stage: 1, information_date: date1, disability_type: 5, disability_response: 1, indefinite_and_impairs: 1 }
  let!(:d1b) { create :hmis_disability, data_source: ds1, client: c1, user: u1, enrollment: e1, data_collection_stage: 1, information_date: date1, disability_type: 6, disability_response: 1 }

  # disability group 2
  let!(:d2a) { create :hmis_disability, data_source: ds1, client: c1, user: u1, enrollment: e2, data_collection_stage: 1, information_date: date2, disability_type: 5, disability_response: 0, indefinite_and_impairs: 0 }
  let!(:d2b) { create :hmis_disability, data_source: ds1, client: c1, user: u1, enrollment: e2, data_collection_stage: 1, information_date: date2, disability_type: 6, disability_response: 0 }

  # disability group 3
  let!(:d3a) { create :hmis_disability, data_source: ds1, client: c1, user: u1, enrollment: e2, data_collection_stage: 2, information_date: date2, disability_type: 10, disability_response: 3 }

  before(:each) do
    hmis_login(user)
  end

  let(:client_query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          disabilityGroups {
            #{scalar_fields(Types::HmisSchema::DisabilityGroup)}
            user {
              id
            }
            enrollment {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'Client lookup with disabilityGroups' do
    it 'should resolve no related records if user does not have view access' do
      response, result = post_graphql(id: c1.id) { client_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')
      expect(client['id']).to eq(c1.id.to_s)
      expect(client['disabilityGroups'].size).to eq(0)
    end

    it 'groups disabilities correctly' do
      assign_viewable(view_access_group, p1.as_warehouse, hmis_user)
      response, result = post_graphql(id: c1.id) { client_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')
      expect(client['id']).to eq(c1.id.to_s)
      groups = client['disabilityGroups']
      expect(groups.size).to eq(3)

      # sorted by most recent date and data collection stage

      # "group 3" only has substance record
      expect(groups[0]['informationDate']).to eq(date2.strftime('%Y-%m-%d'))
      expect(groups[0]['dataCollectionStage']).to eq('UPDATE')
      expect(groups[0]['physicalDisability']).to be_nil
      expect(groups[0]['physicalDisabilityIndefiniteAndImpairs']).to be_nil
      expect(groups[0]['substanceUseDisorder']).to eq('BOTH_ALCOHOL_AND_DRUG_USE_DISORDERS')
      expect(groups[0]['developmentalDisability']).to be_nil

      # "group 2" has physical and developmental (no)
      expect(groups[1]['informationDate']).to eq(date2.strftime('%Y-%m-%d'))
      expect(groups[1]['dataCollectionStage']).to eq('PROJECT_ENTRY')
      expect(groups[1]['physicalDisability']).to eq('NO')
      expect(groups[1]['physicalDisabilityIndefiniteAndImpairs']).to eq('NO')
      expect(groups[1]['substanceUseDisorder']).to be_nil
      expect(groups[1]['developmentalDisability']).to eq('NO')

      # "group 1" has physical and developmental (yes)
      expect(groups[2]['informationDate']).to eq(date1.strftime('%Y-%m-%d'))
      expect(groups[2]['dataCollectionStage']).to eq('PROJECT_ENTRY')
      expect(groups[2]['physicalDisability']).to eq('YES')
      expect(groups[2]['physicalDisabilityIndefiniteAndImpairs']).to eq('YES')
      expect(groups[2]['substanceUseDisorder']).to be_nil
      expect(groups[2]['developmentalDisability']).to eq('YES')
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
