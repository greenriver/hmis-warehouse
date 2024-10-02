###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

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
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: 2.weeks.ago }
  let!(:fd1) do
    # maybe can be replaced by:
    # https://github.com/greenriver/hmis-warehouse/pull/4607/files#r1713723064
    ['fieldOne', 'fieldTwo'].each do |key|
      create(:hmis_custom_data_element_definition, key: key, owner_type: Hmis::Hud::CustomAssessment.sti_name, data_source: ds1)
    end
    create :hmis_form_definition
  end
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    hmis_login(user)
  end

  let(:test_assessment_date) { e1.entry_date.strftime('%Y-%m-%d') }
  let(:test_input) do
    {
      enrollment_id: e1.id.to_s,
      form_definition_id: fd1.id,
      values: { 'linkid_date' => test_assessment_date },
      hud_values: { 'assessmentDate' => test_assessment_date },
    }
  end

  let(:mutation) do
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
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'Submitting a form for the first time' do
    it 'should create assessment successfully' do
      response, result = post_graphql(input: { input: test_input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result&.inspect
        expect(errors).to be_empty
        expect(assessment['id']).to be_present
        expect(assessment['assessmentDate']).to eq(test_assessment_date)
        expect(e1.custom_assessments.count).to eq(1)
        expect(e1.custom_assessments.in_progress.count).to eq(0)
        expect(e1.custom_assessments.first.enrollment_id).to eq(e1.enrollment_id)
      end
    end
  end

  describe 'Re-Submitting a form that has already been submitted' do
    let!(:a1) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1, assessment_date: e1.entry_date }

    it 'should update assessment successfully' do
      expect(e1.custom_assessments.count).to eq(1)

      new_assessment_date = (e1.entry_date + 1.week).strftime('%Y-%m-%d')
      input = {
        assessment_id: a1.id,
        enrollment_id: a1.enrollment.id,
        form_definition_id: fd1.id,
        values: { 'linkid_date' => new_assessment_date },
        hud_values: { 'assessmentDate' => new_assessment_date },
      }
      response, result = post_graphql(input: { input: input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result&.inspect
        expect(errors).to be_empty
        expect(assessment['id']).to be_present
        expect(assessment['assessmentDate']).to eq(new_assessment_date)
        expect(e1.custom_assessments.count).to eq(1)
        expect(e1.custom_assessments.in_progress.count).to eq(0)
      end
    end
  end

  describe 'Submitting a form that was previously saved as WIP' do
    it 'should update and submit assessment successfully' do
      a1_wip = create(:hmis_wip_custom_assessment, data_source: ds1, enrollment: e1, assessment_date: e1.entry_date)
      expect(e1.custom_assessments.in_progress.count).to eq(1)

      new_assessment_date = (e1.entry_date + 1.week).strftime('%Y-%m-%d')
      input = {
        assessment_id: a1_wip.id,
        enrollment_id: a1_wip.enrollment.id,
        form_definition_id: fd1.id,
        values: { 'linkid_date' => new_assessment_date },
        hud_values: { 'assessmentDate' => new_assessment_date },
      }
      response, result = post_graphql(input: { input: input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result&.inspect
        expect(errors).to be_empty
        expect(assessment).to be_present
        expect(assessment['enrollment']).to be_present
        expect(assessment['assessmentDate']).to eq(new_assessment_date)
        expect(assessment['inProgress']).to eq(false)
        expect(e1.custom_assessments.count).to eq(1)
        expect(e1.custom_assessments.in_progress.count).to eq(0)
      end
    end

    it 'should not save if there were unconfirmed warnings' do
      a1_wip = create(:hmis_wip_custom_assessment, data_source: ds1, enrollment: e1, assessment_date: e1.entry_date)
      expect(e1.custom_assessments.in_progress.count).to eq(1)

      new_assessment_date = (e1.entry_date + 5.days).strftime('%Y-%m-%d')
      input = {
        assessment_id: a1_wip.id,
        enrollment_id: a1_wip.enrollment.id,
        form_definition_id: fd1.id,
        values: { 'linkid_date' => new_assessment_date, 'linkid_choice' => nil },
        hud_values: { 'assessmentDate' => new_assessment_date, 'fieldTwo' => nil },
      }
      response, result = post_graphql(input: { input: input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result&.inspect
        expect(errors).to contain_exactly(a_hash_including('severity' => 'warning', 'type' => 'data_not_collected'))
        expect(assessment).to be_nil

        # It is still WIP, and fields should NOT have been updated
        a1_wip.reload
        expect(a1_wip.in_progress?).to eq(true)
        expect(a1_wip.assessment_date).not_to eq(Date.parse(new_assessment_date))
        expect(a1_wip.form_processor.values).not_to include(**input[:values])
        expect(a1_wip.form_processor.hud_values).not_to include(**input[:hud_values])
      end
    end
  end

  describe 'For exit assessment' do
    let(:today) { Date.current }
    let(:fd1) { create(:hmis_exit_assessment_definition) }
    let(:test_input) do
      {
        enrollment_id: e1.id.to_s,
        form_definition_id: fd1.id.to_s,
        values: {
          'exit_date' => today.to_fs(:db),
        },
        hud_values: {
          'Exit.exitDate' => today.to_fs(:db),
        },
      }
    end

    describe 'for enrollment with an invalid entry/exit date' do
      let!(:e1_exit) { create :hmis_hud_exit, data_source: ds1, enrollment: e1, client: e1.client }
      before(:each) do
        e1_exit.exit_date = e1.entry_date - 1.day
        e1_exit.save!(validate: false)
      end

      it 'Should allow correction' do
        response, result = post_graphql(input: { input: test_input }) { mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(errors).to be_empty
        end
      end
    end

    describe 'on project that has ended' do
      before(:each) { p1.update!(operating_end_date: today - 1.day) }
      it 'should be invalid' do
        response, result = post_graphql(input: { input: test_input }) { mutation }
        expect(response.status).to eq(200), result.inspect
        errors = result.dig('data', 'submitAssessment', 'errors')
        expected = Hmis::Hud::Validators::BaseValidator.after_project_end_message(p1.operating_end_date)
        expect(errors).to include(a_hash_including('message' => expected))
      end
    end

    describe 'on project that has not started' do
      before(:each) { p1.update!(operating_start_date: today + 1.day) }
      it 'should be invalid' do
        response, result = post_graphql(input: { input: test_input }) { mutation }
        expect(response.status).to eq(200), result.inspect
        errors = result.dig('data', 'submitAssessment', 'errors')
        expected = Hmis::Hud::Validators::BaseValidator.before_project_start_message(p1.operating_start_date)
        expect(errors).to include(a_hash_including('message' => expected))
      end
    end
  end

  describe 'Validity tests' do
    let!(:e1_exit) { create :hmis_hud_exit, data_source: ds1, enrollment: e1, client: e1.client }
    before(:each) { e1_exit.update(exit_date: 3.days.ago) }

    it 'should error if assessment doesn\'t exist' do
      expect_gql_error post_graphql(input: { input: test_input.merge(assessment_id: '999') }) { mutation }
    end

    it 'should error if form definition is draft' do
      draft = create(:hmis_form_definition, version: 2, status: Hmis::Form::Definition::DRAFT, identifier: fd1.identifier)
      expect_gql_error post_graphql(input: { input: test_input.merge(form_definition_id: draft.id) }) { mutation }
    end

    [
      [
        'should return an error if a required field is missing',
        ->(input) {
          input.merge(
            hud_values: { **input[:hud_values], 'fieldOne' => nil },
            values: { **input[:values], 'linkid_required' => nil },
          )
        },
        {
          'fullMessage' => 'The Required Field must exist',
          'attribute' => 'fieldOne',
          'readableAttribute' => 'The Required Field',
          'type' => 'required',
          'severity' => 'error',
        },
      ],
      [
        'should return warning for data not collected',
        ->(input) {
          input.merge(
            hud_values: { **input[:hud_values], 'fieldTwo': 'DATA_NOT_COLLECTED' },
            values: { **input[:values], 'linkid_choice' => nil },
          )
        },
        {
          'fullMessage' => 'Choice field is empty',
          'attribute' => 'fieldTwo',
          'readableAttribute' => 'Choice field',
          'type' => 'data_not_collected',
          'severity' => 'warning',
        },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input: { input: input }) { mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        aggregate_failures 'checking response' do
          expect(response.status).to eq(200), result.inspect
          expect(errors).to match(expected_errors.map { |h| a_hash_including(**h) })
        end
      end
    end

    [
      [
        'should error if assessment date is missing',
        nil,
        {
          'fullMessage' => 'Assessment Date must exist',
          'type' => 'required',
          'severity' => 'error',
        },
      ],
      [
        'should error if assessment date is before entry date',
        3.weeks.ago,
        {
          'message' => Hmis::Hud::Validators::BaseValidator.before_entry_message(2.weeks.ago),
          'type' => 'out_of_range',
          'severity' => 'error',
        },
      ],
      [
        'should error if assessment date is after exit date',
        1.day.ago,
        {
          'message' => Hmis::Hud::Validators::BaseValidator.after_exit_message(3.days.ago),
          'type' => 'out_of_range',
          'severity' => 'error',
        },
      ],
      [
        'should error if assessment date is in the future',
        Date.current + 5.days,
        {
          'message' => Hmis::Hud::Validators::BaseValidator.future_message,
          'severity' => 'error',
        },
      ],
      [
        'should error if assessment date is >20 years ago',
        25.years.ago,
        {
          'message' => Hmis::Hud::Validators::BaseValidator.over_twenty_years_ago_message,
          'severity' => 'error',
        },
      ],
      [
        'should warn if assessment date is >30 days ago',
        2.months.ago,
        {
          'message' => Hmis::Hud::Validators::BaseValidator.before_entry_message(2.weeks.ago),
          'severity' => 'error',
        },
        {
          'message' => Hmis::Hud::Validators::BaseValidator.over_thirty_days_ago_message,
          'severity' => 'warning',
        },
      ],
    ].each do |test_name, date, *expected_errors|
      it test_name do
        input = test_input.merge(
          hud_values: { 'assessmentDate' => date&.strftime('%Y-%m-%d') },
          values: { 'linkid_date' => date&.strftime('%Y-%m-%d') },
        )
        response, result = post_graphql(input: { input: input }) { mutation }
        errors = result.dig('data', 'submitAssessment', 'errors')
        expect(response.status).to eq(200), result&.inspect

        expected_match = expected_errors.map do |attrs|
          attrs = attrs.merge(
            'readableAttribute' => 'Assessment Date',
            'attribute' => 'assessmentDate',
            'linkId' => 'linkid_date',
          )
          a_hash_including(attrs)
        end
        expect(errors).to match(expected_match)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
