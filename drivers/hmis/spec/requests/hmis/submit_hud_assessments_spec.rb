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
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:test_input) do
    {
      enrollment_id: e1.id,
      confirmed: false,
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
            customForm {
              #{scalar_fields(Types::HmisSchema::CustomForm)}
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
            customForm {
              #{scalar_fields(Types::HmisSchema::CustomForm)}
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
    expect(assessment.custom_form.form_processor).to be_present
    expect(assessment.assessment_date).to eq(expected_assessment_date)
    expect(assessment.enrollment.entry_date).to eq(expected_entry_date) if expected_entry_date.present?
    expect(assessment.enrollment.exit&.exit_date).to eq(expected_exit_date) if expected_exit_date.present?
  end

  describe 'Submitting and then re-submitting HUD assessments' do
    [:INTAKE, :UPDATE, :ANNUAL, :EXIT].each do |role|
      it "#{role}: sets and updates assessment date and entry/exit dates as appropriate" do
        definition = Hmis::Form::Definition.find_by(role: role)
        e1.update(entry_date: 2.weeks.ago)
        enrollment_date_updated = e1.date_updated

        # Create the initial assessment (submit)
        initial_assessment_date = 1.week.ago.strftime('%Y-%m-%d')
        input = { **test_input, form_definition_id: definition.id, **build_minimum_values(definition, assessment_date: initial_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty
        assessment = Hmis::Hud::CustomAssessment.find(assessment_id)
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
        new_assessment_date = Date.yesterday.strftime('%Y-%m-%d')
        input = { assessment_id: assessment.id, **build_minimum_values(definition, assessment_date: new_assessment_date) }
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
        e1.update(entry_date: 2.weeks.ago)
        enrollment_date_updated = e1.date_updated

        # Create the initial assessment (save as WIP)
        initial_assessment_date = 1.week.ago.strftime('%Y-%m-%d')
        input = { **test_input, form_definition_id: definition.id, **build_minimum_values(definition, assessment_date: initial_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { save_assessment_mutation }
        assessment_id = result.dig('data', 'saveAssessment', 'assessment', 'id')
        errors = result.dig('data', 'saveAssessment', 'errors')
        expect(errors).to be_empty
        assessment = Hmis::Hud::CustomAssessment.find(assessment_id)
        expect_assessment_dates(
          assessment,
          expected_assessment_date: initial_assessment_date,
          expected_entry_date: e1.entry_date,
          expected_exit_date: nil,
        )
        expect(assessment.enrollment.date_updated.strftime(TIME_FMT)).to eq(enrollment_date_updated.strftime(TIME_FMT))

        # Update the assessment (submit)
        new_assessment_date = Date.yesterday.strftime('%Y-%m-%d')
        input = { assessment_id: assessment.id, **build_minimum_values(definition, assessment_date: new_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty

        assessment = Hmis::Hud::CustomAssessment.find(assessment_id)
        expect_assessment_dates(
          assessment,
          expected_assessment_date: new_assessment_date,
          expected_entry_date: role == :INTAKE ? new_assessment_date : e1.entry_date,
          expected_exit_date: role == :EXIT ? new_assessment_date : nil,
        )
        expect(assessment.enrollment.date_updated.strftime(TIME_FMT)).not_to eq(enrollment_date_updated.strftime(TIME_FMT))

        # Update the assessment again (submit)
        new_assessment_date = Date.today.strftime('%Y-%m-%d')
        input = { assessment_id: assessment.id, **build_minimum_values(definition, assessment_date: new_assessment_date) }
        _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(errors).to be_empty

        assessment = Hmis::Hud::CustomAssessment.find(assessment_id)
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

  let!(:exited_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: 1.week.ago }
  let!(:exit1) { create :hmis_hud_exit, enrollment: exited_enrollment, data_source: ds1, client: c1, user: u1, exit_date: 3.days.ago }

  it 'Can update the Exit Date when submitting a NEW Exit assessment on an Enrollment that has already been exited (edge case)' do
    definition = Hmis::Form::Definition.find_by(role: :EXIT)
    new_exit_date = Date.yesterday.strftime('%Y-%m-%d')
    input = {
      enrollment_id: exited_enrollment.id,
      form_definition_id: definition.id,
      **build_minimum_values(definition, assessment_date: new_exit_date),
    }
    _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
    assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
    errors = result.dig('data', 'submitAssessment', 'errors')
    expect(errors).to be_empty
    assessment = Hmis::Hud::CustomAssessment.find(assessment_id)
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
    let(:definition) { Hmis::Form::Definition.find_by(role: :EXIT) }

    it 'fails if exiting HoH member' do
      input = { enrollment_id: hoh_enrollment.id, form_definition_id: definition.id, **build_minimum_values(definition) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH.')])
    end

    it 'succeeds if exiting non-HoH member' do
      input = { enrollment_id: open_enrollment2.id, form_definition_id: definition.id, **build_minimum_values(definition) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to be_empty
      expect(assessment_id).to be_present
    end

    it 'fails if trying to create a second exit assessment' do
      input = { enrollment_id: open_enrollment2.id, form_definition_id: definition.id, **build_minimum_values(definition) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to be_empty
      expect(assessment_id).to be_present

      input = { enrollment_id: open_enrollment2.id, form_definition_id: definition.id, **build_minimum_values(definition) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      errors = result.dig('data', 'submitAssessment', 'errors')
      assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'An exit assessment for this enrollment already exists.')])
      expect(assessment_id).to eq(nil)
    end
  end

  describe 'Submitting an Intake assessment in a WIP household' do
    let!(:hoh_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, user: u1, entry_date: '2000-01-01' }
    let!(:other_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, user: u1, entry_date: '2000-01-01', household_id: hoh_enrollment.household_id, relationship_to_ho_h: 99 }
    let(:assessment_date) { '2005-03-02' }
    let(:definition) { Hmis::Form::Definition.find_by(role: :INTAKE) }

    before(:each) do
      hoh_enrollment.build_wip(client: hoh_enrollment.client, date: hoh_enrollment.entry_date, project_id: hoh_enrollment.project.id)
      hoh_enrollment.save_in_progress

      other_enrollment.build_wip(client: other_enrollment.client, date: other_enrollment.entry_date, project_id: other_enrollment.project.id)
      other_enrollment.save_in_progress
    end

    it 'fails if entering non-HoH member' do
      input = { enrollment_id: other_enrollment.id, form_definition_id: definition.id, **build_minimum_values(definition) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'Cannot submit intake assessment because the Head of Household\'s intake has not yet been completed.')])
    end

    it 'succeeds if entering HoH' do
      input = { enrollment_id: hoh_enrollment.id, form_definition_id: definition.id, confirmed: true, **build_minimum_values(definition, assessment_date: assessment_date) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to be_empty
      expect(assessment_id).to be_present
      hoh_enrollment.reload
      expect(hoh_enrollment.entry_date).to eq(Date.parse(assessment_date))
    end

    it 'fails if trying to create a second intake assessment' do
      input = { enrollment_id: hoh_enrollment.id, form_definition_id: definition.id, confirmed: true, **build_minimum_values(definition) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      errors = result.dig('data', 'submitAssessment', 'errors')
      expect(errors).to be_empty
      expect(assessment_id).to be_present

      input = { enrollment_id: hoh_enrollment.id, form_definition_id: definition.id, confirmed: true, **build_minimum_values(definition) }
      _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
      errors = result.dig('data', 'submitAssessment', 'errors')
      assessment_id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      expect(errors).to match([a_hash_including('severity' => 'error', 'fullMessage' => 'An intake assessment for this enrollment already exists.')])
      expect(assessment_id).to eq(nil)
    end
  end

  it 'Resolves errors from IncomeBenefit ActiveRecord validation' do
    definition = Hmis::Form::Definition.find_by(role: :ANNUAL)
    input = {
      enrollment_id: e1.id,
      form_definition_id: definition.id,
      **build_minimum_values(
        definition,
        values: { '4.04.2': 'YES' },
        hud_values: { 'IncomeBenefit.insuranceFromAnySource': 'YES' },
      ),
      confirmed: false,
    }
    _resp, result = post_graphql(input: { input: input }) { submit_assessment_mutation }
    errors = result.dig('data', 'submitAssessment', 'errors')
    expected_error = {
      'severity' => 'error',
      'attribute' => 'insuranceFromAnySource',
      'fullMessage' => Hmis::Hud::Validators::IncomeBenefitValidator::INSURANCE_SOURCES_UNSPECIFIED,
    }
    expect(errors).to match([a_hash_including(expected_error)])

    # Ensure using validate_only gives the same error
    _resp, result = post_graphql(input: { input: input.merge(validate_only: true) }) { submit_assessment_mutation }
    errors = result.dig('data', 'submitAssessment', 'errors')
    expect(errors).to match([a_hash_including(expected_error)])
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
end
