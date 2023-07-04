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
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c4) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2022-01-01' }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, user: u1, entry_date: '2022-01-01', household_id: e1.household_id, relationship_to_ho_h: 99 }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, user: u1, entry_date: '2022-01-01', household_id: e1.household_id, relationship_to_ho_h: 99 }
  let!(:e4) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c4, user: u1, entry_date: '2022-01-01', relationship_to_ho_h: 99 }
  let!(:fd1) { create :hmis_form_definition }
  let!(:exit_fd) { create :hmis_form_definition, role: 'EXIT' }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    hmis_login(user)
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
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:save_input) do
    {
      form_definition_id: fd1.id,
      values: { 'linkid-date' => 2.weeks.ago.strftime('%Y-%m-%d') },
      hud_values: { 'informationDate' => 2.weeks.ago.strftime('%Y-%m-%d') },
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
      expect(Hmis::Hud::CustomAssessment.count).to eq(3)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(3)

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
        expect(Hmis::Hud::CustomAssessment.count).to eq(3)
        expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(0)
      end
    end

    it 'should emit warnings if any assessment is missing warnIfEmpty fields' do
      expect(@wip_assessment_ids.size).to eq(3)
      expect(Hmis::Hud::CustomAssessment.count).to eq(3)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(3)
      Hmis::Hud::CustomAssessment.first.form_processor.update(wip_values: incomplete_values)

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
        expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(3)
      end
    end
    it 'should succeed if existing warnings are confirmed' do
      expect(@wip_assessment_ids.size).to eq(3)
      expect(Hmis::Hud::CustomAssessment.count).to eq(3)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(3)
      Hmis::Hud::CustomAssessment.last.form_processor.update(wip_values: incomplete_values)

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
        expect(Hmis::Hud::CustomAssessment.count).to eq(3)
        expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(0)
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
      expect(Hmis::Hud::CustomAssessment.count).to eq(2)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(2)

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

  describe 'Household intake submission' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_ho_h: 1 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: e1.household_id, relationship_to_ho_h: 8 }
    let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: e1.household_id, relationship_to_ho_h: 8 }
    let!(:a1) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, data_collection_stage: 1 }
    let!(:a2) { create :hmis_custom_assessment, data_source: ds1, enrollment: e2, data_collection_stage: 1 }
    let!(:a3) { create :hmis_custom_assessment, data_source: ds1, enrollment: e3, data_collection_stage: 1 }
    let(:definition) { Hmis::Form::Definition.find_by(role: :INTAKE) }
    let(:input) do
      {
        assessment_ids: [a1.id, a2.id, a3.id],
        confirmed: true,
      }
    end

    before(:each) do
      [a1, a2, a3].each do |assessment|
        assessment.update(assessment_date: 1.week.ago)
        assessment.form_processor.update(
          definition: definition,
          **build_minimum_values(definition, assessment_date: 1.week.ago.strftime('%Y-%m-%d')),
        )
      end
    end

    it 'should succeed if all members have the same entry date' do
      response, result = post_graphql(input: input) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(assessments).to be_present
        expect(errors).to be_empty
      end
    end

    it 'should warn if HoH entry date is later than other members' do
      a1.update(assessment_date: 2.days.ago)
      a1.form_processor.update(**build_minimum_values(definition, assessment_date: 2.days.ago.strftime('%Y-%m-%d')))

      response, result = post_graphql(input: input.merge(confirmed: false)) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      expected_message = Hmis::Hud::Validators::EnrollmentValidator.before_hoh_entry_message(a1.assessment_date)
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(assessments).to be_nil
        expect(errors.size).to eq(2)
        expect(errors).to match([
                                  a_hash_including('severity' => 'warning', 'message' => expected_message, 'recordId' => a2.id.to_s),
                                  a_hash_including('severity' => 'warning', 'message' => expected_message, 'recordId' => a3.id.to_s),
                                ])
      end
    end
  end

  describe 'Household exit submission' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_ho_h: 1 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: e1.household_id, relationship_to_ho_h: 8 }
    let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: e1.household_id, relationship_to_ho_h: 8 }
    let!(:a1) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, data_collection_stage: 3 }
    let!(:a2) { create :hmis_custom_assessment, data_source: ds1, enrollment: e2, data_collection_stage: 3 }
    let!(:a3) { create :hmis_custom_assessment, data_source: ds1, enrollment: e3, data_collection_stage: 3 }
    let(:definition) { Hmis::Form::Definition.find_by(role: :EXIT) }
    let(:input) do
      {
        assessment_ids: [a1.id, a2.id, a3.id],
        confirmed: true,
      }
    end

    before(:each) do
      [a1, a2, a3].each do |assessment|
        assessment.update(assessment_date: 2.days.ago)
        assessment.form_processor.update(
          definition: definition,
          **build_minimum_values(definition, assessment_date: 2.days.ago.strftime('%Y-%m-%d')),
        )
      end
    end

    it 'should succeed if all members have the same entry date' do
      response, result = post_graphql(input: input) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(assessments).to be_present
        expect(errors).to be_empty
      end
    end

    it 'should warn if HoH exit date is earlier than other members' do
      a1.update(assessment_date: 1.week.ago)
      a1.form_processor.update(**build_minimum_values(definition, assessment_date: 1.week.ago.strftime('%Y-%m-%d')))

      response, result = post_graphql(input: input.merge(confirmed: false)) { mutation }
      assessments = result.dig('data', 'submitHouseholdAssessments', 'assessments')
      errors = result.dig('data', 'submitHouseholdAssessments', 'errors')

      expected_hoh_message = Hmis::Hud::Validators::ExitValidator.hoh_exits_before_others
      expected_member_message = Hmis::Hud::Validators::ExitValidator.member_exits_after_hoh(a1.assessment_date)

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(assessments).to be_nil
        expect(errors.size).to eq(3)
        expect(errors).to match([
                                  a_hash_including('severity' => 'warning', 'message' => expected_member_message, 'recordId' => a2.id.to_s),
                                  a_hash_including('severity' => 'warning', 'message' => expected_member_message, 'recordId' => a3.id.to_s),
                                  a_hash_including('severity' => 'warning', 'message' => expected_hoh_message, 'recordId' => a1.id.to_s),
                                ])
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
end
