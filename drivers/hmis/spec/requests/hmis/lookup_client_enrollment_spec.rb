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

  include_context 'hmis base setup'
  include_context 'hmis service setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:c1) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:e2_wip) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:income_benefit) { create :hmis_income_benefit, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:health) { create :hmis_health_and_dv, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:yes) { create :hmis_youth_education_status, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:cls) { create :hmis_current_living_situation, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:ee) { create :hmis_employment_education, data_source: ds1, client: c1, user: u1, enrollment: e1 }
  let!(:disability) { create :hmis_disability, data_source: ds1, client: c1, user: u1, enrollment: e1 }

  let!(:s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let!(:cs1) { create :hmis_custom_service, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1, user: u1 }

  let!(:a1) { create :hmis_custom_assessment, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let!(:ev1) { create :hmis_hud_event, data_source: ds1, client: c1, enrollment: e1, user: u1 }

  before(:each) do
    hmis_login(user)
    e2_wip.save_in_progress
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
          youthEducationStatuses {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::YouthEducationStatus)}
            }
          }
          employmentEducations {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::EmploymentEducation)}
            }
          }
          currentLivingSituations {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::CurrentLivingSituation)}
            }
          }
          disabilityGroups {
            #{scalar_fields(Types::HmisSchema::DisabilityGroup)}
          }
          assessments {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Assessment)}
            }
          }
          services {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Service)}
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
          services {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Service)}
            }
          }
          incomeBenefits {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::IncomeBenefit)}
            }
          }
          healthAndDvs {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::HealthAndDv)}
            }
          }
          youthEducationStatuses {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::YouthEducationStatus)}
            }
          }
          employmentEducations {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::EmploymentEducation)}
            }
          }
          currentLivingSituations {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::CurrentLivingSituation)}
            }
          }
          disabilities {
            nodesCount
            nodes {
              #{scalar_fields(Types::HmisSchema::Disability)}
            }
          }
          disabilityGroups {
            #{scalar_fields(Types::HmisSchema::DisabilityGroup)}
          }
        }
      }
    GRAPHQL
  end

  let(:client_wip_enrollments_query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          enrollments(limit: 10, offset: 0, filters: { status: [INCOMPLETE] }) {
            nodesCount
            nodes {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  let(:client_non_wip_enrollments_query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          enrollments(limit: 10, offset: 0, filters: { status: [ACTIVE, EXITED] }) {
            nodesCount
            nodes {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'Client lookup' do
    it 'should resolve no related records if user does not have view access' do
      remove_permissions(access_control, :can_view_enrollment_details)
      response, result = post_graphql(id: c1.id) { client_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')

      expect(client['id']).to eq(c1.id.to_s)
      expect(client['enrollments']['nodesCount']).to eq(0)
      expect(client['assessments']['nodesCount']).to eq(0)
      expect(client['incomeBenefits']['nodesCount']).to eq(0)
      expect(client['disabilities']['nodesCount']).to eq(0)
      expect(client['healthAndDvs']['nodesCount']).to eq(0)
      expect(client['youthEducationStatuses']['nodesCount']).to eq(0)
      expect(client['employmentEducations']['nodesCount']).to eq(0)
      expect(client['currentLivingSituations']['nodesCount']).to eq(0)
      expect(client['disabilityGroups'].size).to eq(0)
      expect(client['services']['nodesCount']).to eq(0)
    end

    it 'should resolve related records if user has view access' do
      response, result = post_graphql(id: c1.id) { client_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')
      expect(client['id']).to eq(c1.id.to_s)
      expect(client['enrollments']['nodesCount']).to eq(2)
      expect(client['assessments']['nodesCount']).to eq(1)
      expect(client['incomeBenefits']['nodesCount']).to eq(1)
      expect(client['disabilities']['nodesCount']).to eq(1)
      expect(client['healthAndDvs']['nodesCount']).to eq(1)
      expect(client['youthEducationStatuses']['nodesCount']).to eq(1)
      expect(client['employmentEducations']['nodesCount']).to eq(1)
      expect(client['currentLivingSituations']['nodesCount']).to eq(1)
      expect(client['disabilityGroups'].size).to eq(1)
      expect(client['services']['nodesCount']).to eq(2)
    end

    it 'should apply WIP-only limit to enrollments' do
      response, result = post_graphql(id: c1.id) { client_wip_enrollments_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')
      expect(client['id']).to eq(c1.id.to_s)
      expect(client['enrollments']['nodesCount']).to eq(1)
      expect(client['enrollments']['nodes'][0]['id']).to eq(e2_wip.id.to_s)
    end

    it 'should apply non-WIP-only limit to enrollments' do
      response, result = post_graphql(id: c1.id) { client_non_wip_enrollments_query }
      expect(response.status).to eq 200
      client = result.dig('data', 'client')
      expect(client['id']).to eq(c1.id.to_s)
      expect(client['enrollments']['nodesCount']).to eq(1)
      expect(client['enrollments']['nodes'][0]['id']).to eq(e1.id.to_s)
    end
  end

  describe 'Enrollment lookup' do
    it 'should return empty if user does not have view access' do
      remove_permissions(access_control, :can_view_enrollment_details)
      response, result = post_graphql(id: e1.id) { enrollment_query }
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'enrollment')
      expect(enrollment).to be_nil
    end

    it 'should resolve related records if user has view access' do
      response, result = post_graphql(id: e1.id) { enrollment_query }
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'enrollment')
      expect(enrollment['id']).to eq(e1.id.to_s)
      expect(enrollment['status']).to eq('ACTIVE')
      expect(enrollment['services']['nodesCount']).to eq(2)
      expect(enrollment['events']['nodesCount']).to eq(1)
      expect(enrollment['assessments']['nodesCount']).to eq(1)
      expect(enrollment['incomeBenefits']['nodesCount']).to eq(1)
      expect(enrollment['disabilities']['nodesCount']).to eq(1)
      expect(enrollment['healthAndDvs']['nodesCount']).to eq(1)
      expect(enrollment['youthEducationStatuses']['nodesCount']).to eq(1)
      expect(enrollment['employmentEducations']['nodesCount']).to eq(1)
      expect(enrollment['currentLivingSituations']['nodesCount']).to eq(1)
      expect(enrollment['disabilityGroups'].size).to eq(1)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
