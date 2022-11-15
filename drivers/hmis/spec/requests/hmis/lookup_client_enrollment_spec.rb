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
  let!(:income_benefit) { create :hmis_income_benefit, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:health) { create :hmis_health_and_dv, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:disability) { create :hmis_disability, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let!(:a1) { create :hmis_hud_assessment, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let!(:ev1) { create :hmis_hud_event, data_source: ds1, client: c1, enrollment: e1, user: u1 }

  before(:each) do
    hmis_login(user)
  end

  let(:client_query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          #{scalar_fields(Types::HmisSchema::Client)}
          enrollments {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Enrollment)}
            }
          }
          incomeBenefits {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::IncomeBenefit)}
            }
          }
          disabilities {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Disability)}
            }
          }
          healthAndDvs {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::HealthAndDv)}
            }
          }
        }
      }
    GRAPHQL
  end

  let(:enrollment_query) do
    <<~GRAPHQL
      query Enrollment($id: ID!) {
        enrollment(id: $id) {
          #{scalar_fields(Types::HmisSchema::Enrollment)}
          services {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Service)}
            }
          }
          events {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Event)}
            }
          }
          assessments {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Assessment)}
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'Client lookup' do
    it 'should resolve no related records if user does not have view access' do
      response, result = post_graphql(id: c1.id) { client_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')
      expect(client['id']).to eq(c1.id.to_s)
      expect(client['enrollments']['nodesCount']).to eq(0)
      expect(client['incomeBenefits']['nodesCount']).to eq(0)
      expect(client['disabilities']['nodesCount']).to eq(0)
      expect(client['healthAndDvs']['nodesCount']).to eq(0)
    end

    it 'should resolve related records if user has view access' do
      assign_viewable(view_access_group, p1.as_warehouse, hmis_user)
      response, result = post_graphql(id: c1.id) { client_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')
      expect(client['id']).to eq(c1.id.to_s)
      expect(client['enrollments']['nodesCount']).to eq(1)
      expect(client['incomeBenefits']['nodesCount']).to eq(1)
      expect(client['disabilities']['nodesCount']).to eq(1)
      expect(client['healthAndDvs']['nodesCount']).to eq(1)
    end
  end

  describe 'Enrollment lookup' do
    it 'should return empty if user does not have view access' do
      response, result = post_graphql(id: e1.id) { enrollment_query }
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'enrollment')
      expect(enrollment).to be_nil
    end

    it 'should resolve related records if user has view access' do
      assign_viewable(view_access_group, p1.as_warehouse, hmis_user)
      response, result = post_graphql(id: e1.id) { enrollment_query }
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'enrollment')
      expect(enrollment['id']).to eq(e1.id.to_s)
      expect(enrollment['services']['nodesCount']).to eq(1)
      expect(enrollment['events']['nodesCount']).to eq(1)
      expect(enrollment['assessments']['nodesCount']).to eq(1)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
