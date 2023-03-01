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
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:test_input) do
    {
      enrollment_id: e1.id,
      form_definition_id: fd1.id,
      values: { 'linkid-date' => '2023-02-01' },
      hud_values: { 'informationDate' => '2023-02-01' },
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

  describe 'Submitting a form for the first time' do
    it 'should create assessment successfully' do
      response, result = post_graphql(input: { input: test_input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessment['id']).to be_present
        expect(assessment['assessmentDate']).to eq('2023-02-01')
        expect(Hmis::Hud::Assessment.count).to eq(1)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
        expect(Hmis::Hud::Assessment.first.enrollment_id).to eq(e1.enrollment_id)
        details = Hmis::Hud::Assessment.first.assessment_detail
        expect(details.values).to include(test_input[:values])
        expect(details.hud_values).to include(test_input[:hud_values])
      end
    end
  end

  describe 'Re-Submitting a form that has already been submitted' do
    before(:each) do
      # create tha initial submitted assessment
      _resp, result = post_graphql(input: { input: test_input }) { mutation }
      id = result.dig('data', 'submitAssessment', 'assessment', 'id')
      @assessment = Hmis::Hud::Assessment.find(id)
    end

    it 'should update assessment successfully' do
      new_information_date = '2024-01-01'
      input = {
        assessment_id: @assessment.id,
        values: { 'linkid-date' => new_information_date },
        hud_values: { 'informationDate' => new_information_date },
      }
      response, result = post_graphql(input: { input: input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessment['id']).to be_present
        expect(assessment['assessmentDate']).to eq(new_information_date)
        expect(Hmis::Hud::Assessment.count).to eq(1)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
        details = Hmis::Hud::Assessment.first.assessment_detail
        expect(details.values).to include(input[:values])
        expect(details.hud_values).to include(input[:hud_values])
      end
    end
  end

  describe 'Submitting a form that was previously saved as WIP' do
    let(:save_wip_mutation) do
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

    before(:each) do
      # create the initial WIP assessment
      _resp, result = post_graphql(input: { input: test_input }) { save_wip_mutation }
      id = result.dig('data', 'saveAssessment', 'assessment', 'id')
      @assessment = Hmis::Hud::Assessment.find(id)
    end

    it 'should update and submit assessment successfully' do
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)

      new_information_date = '2024-01-01'
      input = {
        assessment_id: @assessment.id,
        values: { 'linkid-date' => new_information_date },
        hud_values: { 'informationDate' => new_information_date },
      }
      response, result = post_graphql(input: { input: input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(assessment).to be_present
        expect(assessment['enrollment']).to be_present
        expect(assessment['assessmentDate']).to eq(new_information_date)
        expect(assessment['inProgress']).to eq(false)
        expect(Hmis::Hud::Assessment.count).to eq(1)
        expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
        expect(Hmis::Hud::Assessment.where(enrollment_id: Hmis::Hud::Assessment::WIP_ID).count).to eq(0)
        expect(Hmis::Wip.count).to eq(0)
        @assessment.reload
        expect(@assessment.in_progress?).to eq(false)
      end
    end

    it 'should save without submitting if there are unconfirmed warnings' do
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)

      new_information_date = '2026-01-01'
      input = {
        assessment_id: @assessment.id,
        values: { 'linkid-date' => new_information_date, 'linkid-choice' => nil },
        hud_values: { 'informationDate' => new_information_date, 'linkid-choice' => nil },
      }
      response, result = post_graphql(input: { input: input }) { mutation }
      assessment = result.dig('data', 'submitAssessment', 'assessment')
      errors = result.dig('data', 'submitAssessment', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to match([a_hash_including('severity' => 'warning', 'type' => 'data_not_collected')])
        expect(assessment).to be_nil

        @assessment.reload
        # It is still WIP, but its values and assessment date have been updated
        expect(@assessment.in_progress?).to eq(true)
        expect(@assessment.assessment_date).to eq(Date.parse(new_information_date))
        expect(@assessment.assessment_detail.values).to include(**input[:values])
        expect(@assessment.assessment_detail.hud_values).to include(**input[:hud_values])
      end
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if assessment doesn\'t exist',
        ->(input) { input.merge(assessment_id: '999') },
        { 'fullMessage' => 'Assessment must exist' },
      ],
      [
        'should return error if a required field is missing',
        ->(input) {
          input.merge(
            hud_values: { 'linkid-date' => '2024-02-01', 'linkid-required' => nil },
            values: { 'linkid-date' => '2024-02-01', 'linkid-required' => nil },
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
            hud_values: { 'linkid-date' => '2024-02-01', 'linkid-choice': 'DATA_NOT_COLLECTED' },
            values: { 'linkid-date' => '2024-02-01', 'linkid-choice' => nil },
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
          expect(response.status).to eq 200
          expect(errors).to match(expected_errors.map { |h| a_hash_including(**h) })
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
