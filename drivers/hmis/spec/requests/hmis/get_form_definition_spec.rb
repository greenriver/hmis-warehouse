require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../models/hmis/form/hmis_form_setup'

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

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetFormDefinition($enrollmentId: ID, $role: FormRole!) {
        getFormDefinition(enrollmentId: $enrollmentId, role: $role) {
          #{form_definition_fragment}
        }
      }
    GRAPHQL
  end

  Hmis::Form::Definition::FORM_ROLES.except(:CE, :POST_EXIT, :CUSTOM).keys.each do |role|
    it 'should find default definition by role' do
      response, result = post_graphql({ enrollment_id: e1.id.to_s, role: role }) { query }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        form_definition = result.dig('data', 'getFormDefinition')
        expect(form_definition).to be_present
        expect(form_definition['role']).to eq(role.to_s)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
