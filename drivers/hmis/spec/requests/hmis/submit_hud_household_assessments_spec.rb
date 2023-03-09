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

  let!(:assessment1) { create :hmis_custom_assessment_with_defaults, data_source: ds1 }
  let!(:assessment2) { create :hmis_custom_assessment_with_defaults, data_source: ds1 }
  let!(:assessment3) { create :hmis_custom_assessment_with_defaults, data_source: ds1 }

  let(:submit_assessment_mutation) do
    <<~GRAPHQL
      mutation SubmitHouseholdAssessments($input: SubmitHouseholdAssessmentsInput!) {
        submitHouseholdAssessments(input: $input) {
          assessments {
            #{scalar_fields(Types::HmisSchema::Assessment)}
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  # Set up all household assessments for a particular role
  def setup_household(role)
    assessment1.enrollment.update(relationship_to_ho_h: 1)
    assessment2.enrollment.update(relationship_to_ho_h: 9)
    assessment3.enrollment.update(relationship_to_ho_h: 9)

    [assessment1, assessment2, assessment3].each do |assessment|
      enrollment = assessment.enrollment
      project = assessment1.enrollment.project # all use the same project
      enrollment.update(household_id: assessment1.enrollment.household_id, project_id: project.project_id)

      # Save enrollment as WIP
      if role == :INTAKE
        enrollment.build_wip(client: enrollment.client, date: enrollment.entry_date, project_id: project.id)
        enrollment.save_in_progress
      end

      # Save assessment as WIP with minimum needed values
      assessment.update(data_collection_stage: role == :INTAKE ? 1 : 3)
      assessment.custom_form.update(**custom_form_attributes(role, assessment.assessment_date))
      assessment.build_wip(enrollment: enrollment, client: enrollment.client, date: assessment.assessment_date, project_id: project.id)
      assessment.save_in_progress
    end
  end

  def validate_setup
    expect(assessment1.in_progress?).to eq(true)
    expect(assessment2.in_progress?).to eq(true)
    expect(assessment3.in_progress?).to eq(true)

    expect(assessment1.enrollment.head_of_household?).to eq(true)
    expect(assessment2.enrollment.head_of_household?).to eq(false)
    expect(assessment3.enrollment.head_of_household?).to eq(false)

    expect(assessment1.enrollment.household_id).to eq(assessment2.enrollment.household_id)
    expect(assessment1.enrollment.household_id).to eq(assessment3.enrollment.household_id)
  end

  describe 'Intake household submission' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, ds1, hmis_user)
      setup_household(:INTAKE)
    end

    it 'fails if (WIP) HoH is not included' do
      validate_setup
      input = {
        assessment_ids: [assessment2.id, assessment3.id],
        confirmed: true,
      }
      _resp, result = post_graphql(input: input) { submit_assessment_mutation }
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'Please include the head of household. Other household members cannot be entered without the HoH.')])
    end

    it 'succeeds if (WIP) HoH is included' do
      validate_setup
      input = {
        assessment_ids: [assessment1.id, assessment2.id, assessment3.id],
        confirmed: true,
      }
      _resp, result = post_graphql(input: input) { submit_assessment_mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      expect(errors).to be_empty
      expect(assessments&.size).to eq(3)
    end
  end

  describe 'Exit household submission' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, ds1, hmis_user)
      setup_household(:EXIT)
    end

    it 'fails if HoH is present and not all members are present' do
      validate_setup
      input = {
        assessment_ids: [assessment1.id, assessment2.id],
        confirmed: true,
      }
      _resp, result = post_graphql(input: input) { submit_assessment_mutation }
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH, or exit all open enrollments.')])
    end

    it 'succeeds if all members are present' do
      validate_setup
      input = {
        assessment_ids: [assessment1.id, assessment2.id, assessment3.id],
        confirmed: true,
      }
      _resp, result = post_graphql(input: input) { submit_assessment_mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      expect(errors).to be_empty
      expect(assessments&.size).to eq(3)
    end

    it 'succeeds if HoH is not present' do
      validate_setup
      input = {
        assessment_ids: [assessment2.id, assessment3.id],
        confirmed: true,
      }
      _resp, result = post_graphql(input: input) { submit_assessment_mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      expect(errors).to be_empty
      expect(assessments&.size).to eq(2)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include AssessmentHelpers
end
