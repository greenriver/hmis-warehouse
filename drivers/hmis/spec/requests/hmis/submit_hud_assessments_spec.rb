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

  TIME_FMT = '%Y-%m-%d %T.%3N'.freeze

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:test_input) do
    {
      enrollment_id: e1.id,
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

  let(:save_assessment_mutation) do
    <<~GRAPHQL
      mutation SaveAssessment($input: SaveAssessmentInput!) {
        saveAssessment(input: $input) {
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

  def expect_assessment_dates(assessment, expected_assessment_date:, expected_entry_date: nil, expected_exit_date: nil)
    expected_assessment_date = Date.parse(expected_assessment_date) if expected_assessment_date.is_a?(String)
    expected_entry_date = Date.parse(expected_entry_date) if expected_entry_date.is_a?(String)
    expected_exit_date = Date.parse(expected_exit_date) if expected_exit_date.is_a?(String)

    expect(assessment).to be_present
    expect(assessment.assessment_detail.assessment_processor).to be_present
    expect(assessment.assessment_date).to eq(expected_assessment_date)
    expect(assessment.enrollment.entry_date).to eq(expected_entry_date) if expected_entry_date.present?
    expect(assessment.enrollment.exit&.exit_date).to eq(expected_exit_date) if expected_exit_date.present?
  end

  def build_values(definition, assessment_date)
    item = definition.assessment_date_item
    field_name = item.field_name
    field_name = 'Exit.exitDate' if field_name == 'exitDate'
    field_name = 'Enrollment.entryDate' if field_name == 'entryDate'
    {
      values: { item.link_id => assessment_date },
      hud_values: { field_name => assessment_date },
    }
  end

  describe 'Submitting and then re-submitting HUD assessments' do
    [:INTAKE, :UPDATE, :ANNUAL, :EXIT].each do |role|
      it "#{role}: sets and updates assessment date and entry/exit dates as appropriate" do
        definition = Hmis::Form::Definition.find_by(role: role)
        enrollment_date_updated = e1.date_updated

        # Create the initial assessment (submit)
        initial_assessment_date = '2005-03-02'
        input = { **test_input, form_definition_id: definition.id, **build_values(definition, initial_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty
        assessment = Hmis::Hud::Assessment.find(assessment_id)
        expect_assessment_dates(
          assessment,
          expected_assessment_date: initial_assessment_date,
          expected_entry_date: role == :INTAKE ? initial_assessment_date : e1.entry_date,
          expected_exit_date: role == :EXIT ? initial_assessment_date : nil,
        )
        # DateUpdate on the Enrollment should have changed
        expect(assessment.enrollment.date_updated.strftime(TIME_FMT)).not_to eq(enrollment_date_updated.strftime(TIME_FMT))
        enrollment_date_updated = assessment.enrollment.date_updated

        # Update the assessment (submit)
        new_assessment_date = '2021-03-01'
        input = { assessment_id: assessment.id, **build_values(definition, new_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty

        assessment.reload
        expect_assessment_dates(
          assessment,
          expected_assessment_date: new_assessment_date,
          expected_entry_date: role == :INTAKE ? new_assessment_date : e1.entry_date,
          expected_exit_date: role == :EXIT ? new_assessment_date : nil,
        )
        # DateUpdate on the Enrollment should have changed
        expect(assessment.enrollment.date_updated.strftime(TIME_FMT)).not_to eq(enrollment_date_updated.strftime(TIME_FMT))
      end
    end
  end

  describe 'Saving and then submitting HUD assessments' do
    [:INTAKE, :UPDATE, :ANNUAL, :EXIT].each do |role|
      it "#{role}: sets and updates assessment date and entry/exit dates as appropriate" do
        definition = Hmis::Form::Definition.find_by(role: role)
        enrollment_date_updated = e1.date_updated

        # Create the initial assessment (save as WIP)
        initial_assessment_date = '2005-03-02'
        input = { **test_input, form_definition_id: definition.id, **build_values(definition, initial_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { save_assessment_mutation }
        assessment_id = result.dig('data', 'saveAssessment', 'assessment', 'id')
        errors = result.dig('data', 'saveAssessment', 'errors')
        expect(errors).to be_empty
        assessment = Hmis::Hud::Assessment.find(assessment_id)
        expect_assessment_dates(
          assessment,
          expected_assessment_date: initial_assessment_date,
          expected_entry_date: e1.entry_date,
          expected_exit_date: nil,
        )
        expect(assessment.enrollment.date_updated.strftime(TIME_FMT)).to eq(enrollment_date_updated.strftime(TIME_FMT))

        # Update the assessment (submit)
        new_assessment_date = '2021-03-01'
        input = { assessment_id: assessment.id, **build_values(definition, new_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty

        assessment = Hmis::Hud::Assessment.find(assessment_id)
        expect_assessment_dates(
          assessment,
          expected_assessment_date: new_assessment_date,
          expected_entry_date: role == :INTAKE ? new_assessment_date : e1.entry_date,
          expected_exit_date: role == :EXIT ? new_assessment_date : nil,
        )
        expect(assessment.enrollment.date_updated.strftime(TIME_FMT)).not_to eq(enrollment_date_updated.strftime(TIME_FMT))
      end
    end
  end

  let!(:exited_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }
  let!(:exit1) { create :hmis_hud_exit, enrollment: exited_enrollment, data_source: ds1, client: c1, user: u1 }

  it 'Can update the Exit Date when submitting a NEW Exit assessment on an Enrollment that has already been exited (edge case)' do
    definition = Hmis::Form::Definition.find_by(role: :EXIT)
    new_exit_date = '2025-03-02'
    input = {
      enrollment_id: exited_enrollment.id,
      form_definition_id: definition.id,
      **build_values(definition, new_exit_date),
    }
    _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
    assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
    errors = result.dig('data', 'submitAssessment', 'errors')
    expect(errors).to be_empty
    assessment = Hmis::Hud::Assessment.find(assessment_id)
    expect_assessment_dates(
      assessment,
      expected_assessment_date: new_exit_date,
      expected_exit_date: new_exit_date,
    )
  end

  describe 'Submitting an Exit assessment in a household with several open enrollments:' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:c4) { create :hmis_hud_client, data_source: ds1, user: u1 }
    let!(:hoh_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, user: u1, entry_date: '2000-01-01' }
    let!(:open_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, user: u1, entry_date: '2000-01-01', household_id: hoh_enrollment.household_id, relationship_to_ho_h: 99 }
    let!(:open_enrollment2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c4, user: u1, entry_date: '2000-01-01', household_id: hoh_enrollment.household_id, relationship_to_ho_h: 99 }

    it 'fails if exiting HoH member' do
      definition = Hmis::Form::Definition.find_by(role: :EXIT)

      # Submit the HoH's assessment
      initial_assessment_date = '2005-03-02'
      input = { enrollment_id: hoh_enrollment.id, form_definition_id: definition.id, **build_values(definition, initial_assessment_date) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH.')])
    end

    it 'succeeds if exiting non-HoH member' do
      definition = Hmis::Form::Definition.find_by(role: :EXIT)

      # Submit the HoH's assessment
      initial_assessment_date = '2005-03-02'
      input = { enrollment_id: open_enrollment2.id, form_definition_id: definition.id, **build_values(definition, initial_assessment_date) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to be_empty
      expect(assessment_id).to be_present
    end
  end

  #   describe 'Submitting an Exit assessment in a household with 2 open enrollments:' do
  #     let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  #     let!(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  #     let!(:c4) { create :hmis_hud_client, data_source: ds1, user: u1 }
  #     let!(:hoh_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, user: u1, entry_date: '2000-01-01' }
  #     let!(:open_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, user: u1, entry_date: '2000-01-01', household_id: hoh_enrollment.household_id, relationship_to_ho_h: 99 }
  #     let!(:exited_enrollment1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, user: u1, entry_date: '2000-01-01', household_id: hoh_enrollment.household_id, relationship_to_ho_h: 99 }
  #     let!(:exit_record1) { create :hmis_hud_exit, enrollment: exited_enrollment1, data_source: ds1, client: c1, user: u1 }

  #     it 'succeeds if exiting HoH member, and automatically sets remaining member as HoH' do
  #       definition = Hmis::Form::Definition.find_by(role: :EXIT)

  #       # Submit the HoH's assessment
  #       initial_assessment_date = '2005-03-02'
  #       input = { enrollment_id: hoh_enrollment.id, form_definition_id: definition.id, **build_values(definition, initial_assessment_date) }
  #       _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
  #       assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
  #       errors = result.dig('data', 'submitAssessment', 'errors')
  #       expect(errors).to be_empty
  #       expect(assessment_id).to be_present

  #       hoh_enrollment.reload
  #       open_enrollment.reload
  #       expect(open_enrollment.head_of_household?).to be true
  #       expect(hoh_enrollment.exit_date).to be_present
  #     end
  #   end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
