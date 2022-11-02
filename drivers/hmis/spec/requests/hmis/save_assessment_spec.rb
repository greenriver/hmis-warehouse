require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }
  let!(:a1) do
    create(
      :hmis_hud_assessment,
      data_source: ds1,
      client: c1,
      user: u1,
      enrollment: e1,
    )
  end
  let!(:ad1) { create(:hmis_form_assessment_detail, definition: fd1, assessment: a1) }
  let(:access_group) { create :hmis_access_group }

  before(:each) do
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    access_group.add_viewable(p1.as_warehouse)
    access_group.add(hmis_user)
  end

  let(:test_input) do
    {
      assessment_id: a1.id,
      assessment_date: '2022-10-16',
      values: { key: 'newValue' },
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation SaveAssessment($assessmentId: ID!, $values: JsonObject!, $assessmentDate: String, $inProgress: Boolean) {
        saveAssessment(input: {
          assessmentId: $assessmentId,
          assessmentDate: $assessmentDate,
          values: $values,
          inProgress: $inProgress,
        }) {
          assessment {
            id
            inProgress
            enrollment {
              id
            }
            user {
              id
            }
            assessmentDate
            assessmentLocation
            assessmentType
            assessmentLevel
            prioritizationStatus
            dateCreated
            dateUpdated
            dateDeleted
            assessmentDetail {
              id
              definition {
                id
                version
                role
                status
                identifier
                definition {
                  item {
                    linkId
                  }
                }
              }
              dataCollectionStage
              role
              status
              values
            }
          }
          errors {
            attribute
            message
            fullMessage
            type
            options
            __typename
          }
        }
      }
    GRAPHQL
  end

  it 'should save an assessment successfully' do
    response, result = post_graphql(**test_input) { mutation }

    expect(response.status).to eq 200
    assessment = result.dig('data', 'saveAssessment', 'assessment')
    errors = result.dig('data', 'saveAssessment', 'errors')
    expect(assessment['id']).to be_present
    expect(assessment).to include(
      'assessmentDate' => test_input[:assessment_date],
      'assessmentDetail' => include(
        'values' => { 'key' => 'newValue' },
      ),
    )
    expect(errors).to be_empty
    expect(Hmis::Hud::Assessment.count).to eq(1)
    expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
    assessment = Hmis::Hud::Assessment.first
    expect(assessment.enrollment_id).to eq(e1.enrollment_id)
  end

  describe 'In progress tests' do
    it 'should set things to in progress if we tell it to' do
      response, result = post_graphql(**test_input.merge(in_progress: true)) { mutation }
      expect(response.status).to eq 200
      assessment = result.dig('data', 'saveAssessment', 'assessment')
      errors = result.dig('data', 'saveAssessment', 'errors')
      expect(assessment).to be_present
      expect(assessment['inProgress']).to eq(true)
      expect(assessment['enrollment']).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Assessment.count).to eq(1)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)
      expect(Hmis::Hud::Assessment.where(enrollment_id: Hmis::Hud::Assessment::WIP_ID).count).to eq(1)
      expect(Hmis::Wip.count).to eq(1)
      expect(Hmis::Wip.first).to have_attributes(enrollment_id: e1.id, client_id: c1.id, project_id: nil)
      expect(Hmis::Hud::Assessment.viewable_by(hmis_user).count).to eq(1)
    end

    it 'set enrollment ID correctly when WIP assessment is saved as non-WIP' do
      response, = post_graphql(**test_input.merge(in_progress: true)) { mutation }
      expect(response.status).to eq 200
      expect(Hmis::Hud::Assessment.count).to eq(1)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(1)

      response, = post_graphql(test_input) { mutation }
      expect(response.status).to eq 200
      expect(Hmis::Hud::Assessment.count).to eq(1)
      expect(Hmis::Hud::Assessment.in_progress.count).to eq(0)
      assessment = Hmis::Hud::Assessment.first
      expect(assessment.enrollment_id).to eq(e1.enrollment_id)
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if assessment doesn\'t exist',
        ->(input) { input.merge(assessment_id: '999') },
        {
          'message' => 'Assessment must exist',
          'attribute' => 'assessmentId',
        },
      ],
    ].each do |test_name, input_proc, *expected_errors|
      it test_name do
        input = input_proc.call(test_input)
        response, result = post_graphql(input) { mutation }
        errors = result.dig('data', 'saveAssessment', 'errors')
        expect(response.status).to eq 200
        expect(errors).to contain_exactly(*expected_errors.map { |error_attrs| include(**error_attrs) })
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
