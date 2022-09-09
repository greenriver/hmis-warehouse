require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:user) { create :user }
  let(:ds1) { create :hmis_data_source }
  let(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let(:p1) { create :hmis_hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1 }
  let(:test_input) do
    {
      project_id: p1.id,
      start_date: Date.today.strftime('%Y-%m-%d'),
      household_members: [
        {
          id: c1.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(1).first,
        },
        {
          id: c2.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(2).first,
        },
        {
          id: c3.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(3).first,
        },
      ],
    }
  end

  describe 'enrollment creation tests' do
    before(:each) do
      user.add_viewable(ds1)
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateEnrollment($input: CreateEnrollmentInput!) {
          createEnrollment(input: $input) {
            enrollments {
              id
              entryDate
              inProgress
              client {
                id
              }
              project {
                id
              }
            }
            errors {
              id
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

    it 'should create an enrollment successfully' do
      response, result = post_graphql(input: test_input) { mutation }

      expect(response.status).to eq 200
      enrollments = result.dig('data', 'createEnrollment', 'enrollments')
      errors = result.dig('data', 'createEnrollment', 'errors')
      expect(enrollments).to be_present
      expect(enrollments.count).to eq(3)
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.count).to eq(3)
      expect(Hmis::Hud::Enrollment.in_progress.count).to eq(0)
      expect(Hmis::Hud::Enrollment.all).to include(
        *enrollments.map do |e|
          have_attributes(
            enrollment_id: be_present,
            project_id: Hmis::Hud::Project.find(test_input[:project_id]).project_id,
            personal_id: Hmis::Hud::Client.find(e['client']['id'].to_i).personal_id,
          )
        end,
      )
    end

    describe 'In progress tests' do
      it 'should set things to in progress if we tell it to' do
        response, result = post_graphql(input: test_input.merge(in_progress: true)) { mutation }
        expect(response.status).to eq 200
        enrollments = result.dig('data', 'createEnrollment', 'enrollments')
        errors = result.dig('data', 'createEnrollment', 'errors')
        expect(enrollments).to be_present
        expect(enrollments.count).to eq(3)
        expect(enrollments.pluck('inProgress').uniq).to eq([true])
        expect(enrollments.pluck('project')).to all(be_present)
        expect(errors).to be_empty
        expect(Hmis::Hud::Enrollment.count).to eq(3)
        expect(Hmis::Hud::Enrollment.in_progress.count).to eq(3)
        expect(Hmis::Hud::Enrollment.where(project_id: nil).count).to eq(3)
        expect(Hmis::Wip.count).to eq(3)
        # byebug
        expect(Hmis::Wip.all).to include(*enrollments.map { |e| have_attributes(enrollment_id: e['id'].to_i, project_id: test_input[:project_id], client_id: e['client']['id'].to_i) })
      end
    end

    describe 'Validity tests' do
      [
        [
          'should emit error if none of the clients are HoH',
          ->(input) { input.merge(household_members: input[:household_members][1..]) },
          {
            'message' => 'Exactly one client must be head of household',
            'attribute' => 'relationshipToHoH',
          },
        ],
        [
          'should emit error if entry date is in the future',
          ->(input) { input.merge(start_date: (Date.today + 1.day).strftime('%Y-%m-%d')) },
          {
            'message' => 'Entry date cannot be in the future',
            'attribute' => 'startDate',
          },
        ],
        [
          'should emit error if project doesn\'t exist',
          ->(input) { input.merge(project_id: '0') },
          {
            'message' => "Project with id '0' does not exist",
            'attribute' => 'projectId',
          },
        ],
      ].each do |test_name, input_proc, error_attrs|
        it test_name do
          input = input_proc.call(test_input)
          response, result = post_graphql(input: input) { mutation }

          enrollments = result.dig('data', 'createEnrollment', 'enrollments')
          errors = result.dig('data', 'createEnrollment', 'errors')
          expect(response.status).to eq 200
          expect(enrollments).to be_empty
          expect(errors).to contain_exactly(
            include(**error_attrs),
          )
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
