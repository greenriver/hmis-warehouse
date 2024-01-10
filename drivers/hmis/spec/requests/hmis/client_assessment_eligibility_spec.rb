###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Graphql HMIS Assessment Eligibility', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query GetClientAssessmentEligibilities($clientId: ID!, $enrollmentId: ID!) {
        client(id: $clientId) {
          id
          assessmentEligibilities(enrollmentId: $enrollmentId) {
            id
            title
            formDefinitionId
            role
            __typename
          }
          __typename
        }
      }
    GRAPHQL
  end
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:each) do
    hmis_login(user)
  end

  it 'resolves shows all HUD assessments by default' do
    response, result = post_graphql(clientId: c1.id, enrollmentId: e1.id) { query }
    expect(response.status).to eq(200)
    records = result.dig('data', 'client', 'assessmentEligibilities').map { |n| n['role'] }
    expect(records).to eq(['INTAKE', 'EXIT', 'ANNUAL'])
  end
end
