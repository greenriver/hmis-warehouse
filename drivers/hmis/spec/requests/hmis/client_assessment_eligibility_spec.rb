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

  def run_query(client:, enrollment:)
    response, result = post_graphql(clientId: client.id, enrollmentId: enrollment.id) { query }
    expect(response.status).to eq(200)
    result.dig('data', 'client', 'assessmentEligibilities').map { |n| n['role'] }
  end

  it 'resolves intake, exit, annual' do
    records = run_query(client: c1, enrollment: e1)
    expect(records).to contain_exactly('INTAKE', 'EXIT', 'ANNUAL')
  end

  context 'with project entry' do
    before(:each) do
      create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, data_collection_stage: 1)
    end
    it 'resolves exit and annual' do
      records = run_query(client: c1, enrollment: e1)
      expect(records).to contain_exactly('EXIT', 'ANNUAL')
    end

    context 'with project exit' do
      before(:each) do
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, data_collection_stage: 3)
      end
      it 'resolves post-exit and annual' do
        records = run_query(client: c1, enrollment: e1)
        expect(records).to contain_exactly('POST_EXIT')
      end
      context 'with project post-exit' do
        before(:each) do
          create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, data_collection_stage: 6)
        end
        it 'resolves nothing' do
          records = run_query(client: c1, enrollment: e1)
          expect(records).to be_empty
        end
      end
    end
  end
end
