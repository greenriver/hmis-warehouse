require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'
require_relative 'hmis_form_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'hmis form setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    hmis_login(user)
  end

  let(:input) do
    {
      enrollment_id: e1.id.to_s,
      assessment_role: 'INTAKE',
    }
  end

  let(:find_by_role_query) do
    <<~GRAPHQL
      query FindFormDefinitionByRole($enrollmentId: ID!, $assessmentRole: AssessmentRole!) {
        getFormDefinition(enrollmentId: $enrollmentId, assessmentRole: $assessmentRole) {
          #{form_definition_fragment}
        }
      }
    GRAPHQL
  end

  let(:lookup_query) do
    <<~GRAPHQL
      query LookupFormDefinition($identifier: String!) {
        formDefinition(identifier: $identifier) {
          #{form_definition_fragment}
        }
      }
    GRAPHQL
  end

  it 'should find definition by role' do
    response, result = post_graphql(**input) { find_by_role_query }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      form_definition = result.dig('data', 'getFormDefinition')
      expect(form_definition['id']).to eq(fd1.id.to_s)
    end
  end

  it 'should resolve base assessment form definition' do
    response, _result = post_graphql(identifier: base_assessment_form_definition.identifier) { lookup_query }

    expect(response.status).to eq 200
  end

  it 'should resolve record-editing form definitions' do
    [
      client_form_definition,
      funder_form_definition,
      inventory_form_definition,
      organization_form_definition,
      project_coc_form_definition,
      project_form_definition,
      search_form_definition,
    ].each do |form_def|
      response, _result = post_graphql(identifier: form_def.identifier) { lookup_query }
      expect(response.status).to eq 200
    end
  end

  # Could add more cases here, but tests for the specific definition resolution logic are already in spec/models/hmis/form/definition_spec.rb
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
