require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'
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
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:test_input) do
    {
      enrollment_id: e1.id,
      values: { 'key' => 'value' },
    }
  end

  let(:submit_assessment_mutation) do
    <<~GRAPHQL
      mutation SubmitAssessment($input: SubmitAssessmentInput!) {
        submitAssessment(input: $input) {
          assessment {
            #{scalar_fields(Types::HmisSchema::Assessment)}
            enrollment {
              id
            }
            user {
              id
            }
            client {
              id
            }
            assessmentDetail {
              #{scalar_fields(Types::HmisSchema::AssessmentDetail)}
              definition {
                id
              }
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'Submitting and then re-submitting an existing HUD assessment' do
    [:INTAKE, :UPDATE, :ANNUAL, :EXIT].each do |role|
      it "#{role}: sets and updates assessment date and entry/exit dates as appropriate" do
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        enrollment_date_updated = e1.date_updated

        # Create the initial assessment
        initial_assessment_date = '2005-03-02'
        input = { **test_input, form_definition_id: definition.id, hud_values: { link_id => initial_assessment_date } }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty
        assessment = Hmis::Hud::Assessment.find(assessment_id)
        expect(assessment).to be_present
        expect(assessment.assessment_detail.assessment_processor).to be_present
        expect(assessment.assessment_date).to eq(Date.parse(initial_assessment_date))
        expect(assessment.enrollment.entry_date).to eq(Date.parse(initial_assessment_date)) if role == :INTAKE
        expect(assessment.enrollment.exit&.exit_date).to eq(Date.parse(initial_assessment_date)) if role == :EXIT
        expect(assessment.enrollment.date_updated.inspect).not_to be == enrollment_date_updated.inspect
        enrollment_date_updated = assessment.enrollment.date_updated

        # Update the assessment
        new_assessment_date = '2021-03-01'
        input = { assessment_id: assessment.id, hud_values: { link_id => new_assessment_date } }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty

        assessment.reload
        expect(assessment.assessment_date).to eq(Date.parse(new_assessment_date))
        expect(assessment.enrollment.entry_date).to eq(Date.parse(new_assessment_date)) if role == :INTAKE
        expect(assessment.enrollment&.exit&.exit_date).to eq(Date.parse(new_assessment_date)) if role == :EXIT
        expect(assessment.enrollment.date_updated.inspect).not_to be == enrollment_date_updated.inspect
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
