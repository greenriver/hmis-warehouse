###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:today) do
    Date.current
  end
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: today - 2.weeks }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    hmis_login(user)
  end

  let(:test_assessment_date) { (e1.entry_date + 2.days).strftime('%Y-%m-%d') }
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
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:get_enrollment_query) do
    <<~GRAPHQL
      query GetEnrollment($id: ID!) {
        enrollment(id: $id) {
          assessments {
            nodesCount
            nodes {
              id
              inProgress
            }
          }
        }
      }
    GRAPHQL
  end

  it 'should create and update a WIP assessment successfully' do
    # Create new WIP assessment
    response, result = post_graphql(input: { input: test_input }) { mutation }
    assessment = result.dig('data', 'saveAssessment', 'assessment')
    errors = result.dig('data', 'saveAssessment', 'errors')

    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result&.inspect
      expect(errors).to be_empty
      expect(assessment).to be_present
      expect(assessment['enrollment']).to be_present
      expect(assessment).to include(
        'inProgress' => true,
        'assessmentDate' => test_assessment_date,
        'wipValues' => test_input[:values],
      )
      expect(Hmis::Hud::CustomAssessment.count).to eq(1)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(1)
      expect(Hmis::Hud::CustomAssessment.viewable_by(hmis_user).count).to eq(1)
    end

    # WIP assessment should appear on enrollment query
    response, result = post_graphql(id: e1.id) { get_enrollment_query }
    expect(response.status).to eq(200), result&.inspect
    enrollment = result.dig('data', 'enrollment')
    expect(enrollment).to be_present
    expect(enrollment.dig('assessments', 'nodes', 0, 'id')).to eq(assessment['id'])
  end

  it 'update an existing WIP assessment successfully' do
    # Create new WIP assessment
    response, result = post_graphql(input: { input: test_input }) { mutation }
    assessment_id = result.dig('data', 'saveAssessment', 'assessment', 'id')
    errors = result.dig('data', 'saveAssessment', 'errors')
    expect(errors).to be_empty
    expect(assessment_id).to be_present
    expect(Hmis::Hud::CustomAssessment.count).to eq(1)
    expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(1)

    # Subsequent request should update the existing WIP assessment
    new_information_date = (e1.entry_date + 1.week).strftime('%Y-%m-%d')
    input = test_input.merge({
                               assessment_id: assessment_id,
                               values: { 'linkid_date' => new_information_date },
                               hud_values: { 'assessmentDate' => new_information_date },
                             })

    response, result = post_graphql(input: { input: input }) { mutation }
    assessment = result.dig('data', 'saveAssessment', 'assessment')
    errors = result.dig('data', 'saveAssessment', 'errors')
    aggregate_failures 'checking response' do
      expect(response.status).to eq(200), result&.inspect
      expect(errors).to be_empty
      expect(assessment).to be_present
      expect(assessment['enrollment']).to be_present
      expect(assessment).to include(
        'inProgress' => true,
        'assessmentDate' => new_information_date,
        'wipValues' => input[:values],
      )
      expect(Hmis::Hud::CustomAssessment.count).to eq(1)
      expect(Hmis::Hud::CustomAssessment.in_progress.count).to eq(1)
    end
  end

  describe 'Validity tests' do
    let!(:e1_exit) { create :hmis_hud_exit, data_source: ds1, enrollment: e1, client: e1.client }
    before(:each) { e1_exit.update(exit_date: today - 3.days) }

    [
      [
        'should error if enrollment doesn\'t exist',
        ->(input) { input.merge(enrollment_id: '999') },
      ],
      [
        'should error if cannot find form definition',
        ->(input) { input.merge(form_definition_id: '999') },
      ],
      [
        'should error if cannot find assessment',
        ->(input) { input.merge(assessment_id: '999') },
      ],
    ].each do |test_name, input_proc|
      it test_name do
        input = input_proc.call(test_input)
        expect_gql_error post_graphql(input: { input: input }) { mutation }
      end
    end

    it 'should error if enrollment is not provided' do
      my_input = test_input.except(:enrollment_id)
      expect do
        expect_gql_error post_graphql(input: { input: my_input }) { mutation }
      end.to raise_error(RuntimeError)
    end

    it 'should error if form definition is draft' do
      draft = create(:hmis_form_definition, version: 2, status: Hmis::Form::Definition::DRAFT, identifier: fd1.identifier)
      expect_gql_error post_graphql(input: { input: test_input.merge(form_definition_id: draft.id) }) { mutation }
    end

    [
      [
        'should error if assessment date is missing',
        ->(_date) { nil },
        ->(_date) do
          [
            {
              'fullMessage' => 'Assessment Date must exist',
              'type' => 'required',
              'severity' => 'error',
            },
          ]
        end,
      ],
      [
        'should error if assessment date is before entry date',
        ->(date) { date - 3.weeks },
        ->(date) do
          [
            {
              'message' => Hmis::Hud::Validators::BaseValidator.before_entry_message(date - 2.weeks),
              'type' => 'out_of_range',
              'severity' => 'error',
            },
          ]
        end,
      ],
      [
        'should error if assessment date is after exit date',
        ->(date) { date - 1.day },
        ->(date) do
          [
            {
              'message' => Hmis::Hud::Validators::BaseValidator.after_exit_message(date - 3.days),
              'type' => 'out_of_range',
              'severity' => 'error',
            },
          ]
        end,
      ],
      [
        'should error if assessment date is in the future',
        ->(date) { date + 5.days },
        ->(_date) do
          [
            {
              'message' => Hmis::Hud::Validators::BaseValidator.future_message,
              'severity' => 'error',
            },
          ]
        end,
      ],
      [
        'should error if assessment date is >20 years ago',
        ->(date) { date - 25.years },
        ->(_date) do
          [
            {
              'message' => Hmis::Hud::Validators::BaseValidator.over_twenty_years_ago_message,
              'severity' => 'error',
            },
          ]
        end,
      ],
      [
        'should not warn if assessment date is >30 days ago',
        ->(date) { date - 2.months },
        ->(date) do
          [
            {
              'message' => Hmis::Hud::Validators::BaseValidator.before_entry_message(date - 2.weeks),
              'severity' => 'error',
            },
          ]
        end,
      ],
    ].each do |test_name, date_cb, expected_errors_cb|
      it test_name do
        date = date_cb.call(today)
        expected_errors = expected_errors_cb.call(today)

        input = test_input.merge(
          hud_values: { 'assessmentDate' => date&.strftime('%Y-%m-%d') },
          values: { 'linkid_date' => date&.strftime('%Y-%m-%d') },
        )
        response, result = post_graphql(input: { input: input }) { mutation }
        errors = result.dig('data', 'saveAssessment', 'errors')
        expect(response.status).to eq(200), result&.inspect
        expected_match = expected_errors.map do |h|
          a_hash_including(**h, 'readableAttribute' => 'Assessment Date',
                                'attribute' => 'assessmentDate',
                                'linkId' => 'linkid_date')
        end
        expect(errors).to match(expected_match)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
