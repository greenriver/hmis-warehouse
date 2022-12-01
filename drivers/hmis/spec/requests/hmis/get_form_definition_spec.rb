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

  let(:query) do
    <<~GRAPHQL
      query GetFormDefinition($enrollmentId: ID!, $assessmentRole: AssessmentRole!) {
        getFormDefinition(enrollmentId: $enrollmentId, assessmentRole: $assessmentRole) {
          #{scalar_fields(Types::Forms::FormDefinition)}
          definition {
            item {
              #{scalar_fields(Types::Forms::FormItem)}
              pickListOptions {
                #{scalar_fields(Types::Forms::PickListOption)}
              }
              enableWhen {
                #{scalar_fields(Types::Forms::EnableWhen)}
              }
              autofillValues {
                #{scalar_fields(Types::Forms::AutofillValue)}
                autofillWhen {
                  #{scalar_fields(Types::Forms::EnableWhen)}
                }
              }
              item {
                linkId
              }
            }
          }
        }
      }
    GRAPHQL
  end

  it 'should get a form definition successfully' do
    response, result = post_graphql(**input) { query }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      form_definition = result.dig('data', 'getFormDefinition')
      expect(form_definition['id']).to eq(fd1.id.to_s)
    end
  end

  # Could add more cases here, but tests for the specific definition resolution logic are already in spec/models/hmis/form/definition_spec.rb
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
