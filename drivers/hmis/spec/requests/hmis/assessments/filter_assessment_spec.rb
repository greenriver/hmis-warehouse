#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:intake_assessment) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 1 }
  let!(:annual_assessment) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 5 }
  let!(:fd1) { create(:hmis_form_definition, identifier: 'fully-custom-assessment-identifier', role: 'CUSTOM_ASSESSMENT', title: 'Fancy form') }
  let!(:fully_custom_assessment) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1, data_collection_stage: 99, definition: fd1 }

  before(:each) do
    hmis_login(user)
  end

  let(:project_assessments_query) do
    <<~GRAPHQL
      query GetProjectAssessments(
        $id: ID!
        $filters: AssessmentsForProjectFilterOptions = null
      ) {
        project(id: $id) {
          assessments(
            filters: $filters
          ) {
            nodes {
              id
              role
              definition {
                title
              }
            }
          }
        }
      }
    GRAPHQL
  end

  let(:client_assessments_query) do
    <<~GRAPHQL
      query GetClientAssessments(
        $id: ID!
        $filters: AssessmentFilterOptions = null
      ) {
        client(id: $id) {
          assessments(
            filters: $filters
          ) {
            nodes {
              id
              role
              definition {
                title
              }
            }
          }
        }
      }
    GRAPHQL
  end

  it 'should return all assessments when no filter is passed' do
    response, result = post_graphql(id: p1.id, filters: {}) { project_assessments_query }
    expect(response.status).to eq 200
    assessments = result.dig('data', 'project', 'assessments', 'nodes')
    expect(assessments.count).to eq 3
  end

  it 'should return only intake when intake filter is passed' do
    response, result = post_graphql(id: p1.id, filters: { assessment_name: 'INTAKE' }) { project_assessments_query }
    expect(response.status).to eq 200
    assessments = result.dig('data', 'project', 'assessments', 'nodes')
    expect(assessments.count).to eq 1
    expect(assessments.first['id']).to eq(intake_assessment.id.to_s)
  end

  it 'should return both intake and fully custom assessment when both filters are passed' do
    response, result = post_graphql(id: p1.id, filters: { assessment_name: ['INTAKE', 'fully-custom-assessment-identifier'] }) { project_assessments_query }
    expect(response.status).to eq 200
    assessments = result.dig('data', 'project', 'assessments', 'nodes')
    expect(assessments).to contain_exactly(
      a_hash_including('id' => intake_assessment.id.to_s),
      a_hash_including('id' => fully_custom_assessment.id.to_s),
    )
  end

  it 'should return intake even if it is not tied to a definition' do
    intake_assessment.form_processor.update!(definition: nil)
    response, result = post_graphql(id: p1.id, filters: { assessment_name: ['INTAKE'] }) { project_assessments_query }
    expect(response.status).to eq 200
    assessments = result.dig('data', 'project', 'assessments', 'nodes')
    expect(assessments.count).to eq 1
    expect(assessments.first['id']).to eq(intake_assessment.id.to_s)
  end

  it 'should return all assessments for project when project filter is passed' do
    response, result = post_graphql(id: c1.id, filters: { project: [p1.id] }) { client_assessments_query }
    expect(response.status).to eq 200
    assessments = result.dig('data', 'client', 'assessments', 'nodes')
    expect(assessments.count).to eq 3
  end
end
