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
  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let(:assessment1) { create :hmis_wip_custom_assessment, data_source: ds1 }
  let(:assessment2) { create :hmis_wip_custom_assessment, data_source: ds1 }
  let(:assessment3) { create :hmis_wip_custom_assessment, data_source: ds1 }
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

      definition = Hmis::Form::Definition.find_by(role: role)
      raise "No definition for role #{role}" unless definition.present?

      # Save assessment as WIP with minimum needed values
      assessment.update(data_collection_stage: role == :INTAKE ? 1 : 3)
      assessment.form_processor.update(definition: definition, **build_minimum_values(definition, assessment_date: assessment.assessment_date))
      assessment.definition = definition
      assessment.save!
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
  c.include FormHelpers
end
