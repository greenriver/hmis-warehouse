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
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2022-01-01' }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2022-01-01', household_id: e1.household_id }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2022-01-01', household_id: e1.household_id }
  let!(:e4) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2022-01-01' }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation SubmitHouseholdAssessments($input: SubmitHouseholdAssessmentsInput!) {
        submitHouseholdAssessments(input: $input) {
          assessments {
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

  let(:save_input) do
    {
      form_definition_id: fd1.id,
      values: { 'linkid-date' => '2023-02-01' },
      hud_values: { 'informationDate' => '2023-02-01' },
    }
  end
  let(:incomplete_values) { { **save_input[:values], 'linkid-choice' => nil } }

  let(:save_assessment) do
    <<~GRAPHQL
      mutation SaveAssessment($input: SaveAssessmentInput!) {
        saveAssessment(input: $input) {
          assessment {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'Submitting multiple saved assessments' do
    before(:each) do
      # create the initial WIP assessments
      @wip_assessment_ids = []
      [e1, e2, e3].each do |e|
        _resp, result = post_graphql(input: { input: { enrollment_id: e.id, **save_input } }) { save_assessment }
        id = result.dig('data', 'saveAssessment', 'assessment', 'id')
        @wip_assessment_ids.push(id)
      end
    end

    it 'should work' do
      expect(@wip_assessment_ids.size).to eq(3)
      expect(Hmis::Hud::Assessment.count).to eq(3)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(3)

      input = {
        assessment_ids: @wip_assessment_ids,
        confirmed: false,
      }
      response, result = post_graphql(input: input) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessments).to be_present
        expect(assessments.size).to eq(3)
        expect(Hmis::Hud::Assessment.count).to eq(3)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
      end
    end

    it 'should emit warnings if any assessment is missing warnIfEmpty fields' do
      expect(@wip_assessment_ids.size).to eq(3)
      expect(Hmis::Hud::Assessment.count).to eq(3)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(3)
      Hmis::Hud::Assessment.first.assessment_detail.update(values: incomplete_values)

      input = {
        assessment_ids: @wip_assessment_ids,
        confirmed: false,
      }
      response, result = post_graphql(input: input) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(assessments).to be_nil
        expect(errors.size).to eq(1)
        expect(errors).to match([a_hash_including('severity' => 'warning', 'type' => 'data_not_collected')])
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(3)
      end
    end
    it 'should succeed if existing warnings are confirmed' do
      expect(@wip_assessment_ids.size).to eq(3)
      expect(Hmis::Hud::Assessment.count).to eq(3)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(3)
      Hmis::Hud::Assessment.last.assessment_detail.update(values: incomplete_values)

      input = {
        assessment_ids: @wip_assessment_ids,
        confirmed: true,
      }
      response, result = post_graphql(input: input) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessments).to be_present
        expect(assessments.size).to eq(3)
        expect(Hmis::Hud::Assessment.count).to eq(3)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
      end
    end
  end

  describe 'Submitting multiple saved assessments that belong to different households' do
    before(:each) do
      # create the initial WIP assessments
      @wip_assessment_ids = []
      [e1, e4].each do |e|
        _resp, result = post_graphql(input: { input: { enrollment_id: e.id, **save_input } }) { save_assessment }
        id = result.dig('data', 'saveAssessment', 'assessment', 'id')
        @wip_assessment_ids.push(id)
      end
    end

    it 'should fail' do
      expect(@wip_assessment_ids.size).to eq(2)
      expect(Hmis::Hud::Assessment.count).to eq(2)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(2)

      input = {
        assessment_ids: @wip_assessment_ids,
        confirmed: true,
      }
      response, result = post_graphql(input: input) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(assessments).to be_nil
        expect(errors.size).to eq(1)
        expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'Assessments must all belong to the same household.')])
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
