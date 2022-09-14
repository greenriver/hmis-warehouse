require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:user) { create :user }
  let(:ds1) { create :hmis_data_source }
  let(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let(:p1) { create :hmis_hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1 }
  let(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1 }

  let(:test_input) do
    {
      household_id: enrollment.household_id,
      start_date: Date.today.strftime('%Y-%m-%d'),
      household_members: [
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

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'enrollment creation tests' do
    before(:each) do
      user.add_viewable(ds1)
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })

      @hmis_user = Hmis::User.find(user.id)
      @hmis_user.hmis_data_source_id = ds1.id
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation AddHouseholdMembersToEnrollment($input: AddHouseholdMembersToEnrollmentInput!) {
          addHouseholdMembersToEnrollment(input: $input) {
            enrollments {
              id
              entryDate
              inProgress
              relationshipToHoH
              client {
                id
              }
              project {
                id
              }
              household {
                householdClients {
                  id
                  relationshipToHoH
                }
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

    it 'should add members to an enrollment correctly' do
      response, result = post_graphql(input: test_input) { mutation }

      expect(response.status).to eq 200
      enrollments = result.dig('data', 'addHouseholdMembersToEnrollment', 'enrollments')
      errors = result.dig('data', 'addHouseholdMembersToEnrollment', 'errors')
      expect(enrollments).to be_present
      expect(enrollments.count).to eq(2)
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.count).to eq(3)
      expect(Hmis::Hud::Enrollment.in_progress.count).to eq(2)
      expect(Hmis::Hud::Enrollment.in_progress).to include(
        *enrollments.map do |e|
          have_attributes(
            enrollment_id: be_present,
            household_id: test_input[:household_id],
            relationship_to_ho_h: Hmis::Hud::Enrollment.find(e['id']).relationship_to_ho_h,
            project_id: nil,
            personal_id: Hmis::Hud::Client.find(e['client']['id'].to_i).personal_id,
          )
        end,
      )
    end

    describe 'Validity tests' do
      [
        [
          'should emit error if trying to add HoH member when one already exists',
          ->(input) do
            input[:household_members][0][:relationship_to_ho_h] = Types::HmisSchema::Enums::RelationshipToHoH.enum_member_for_value(1).first
            input
          end,
          {
            'message' => 'Enrollment already has a head of household designated',
            'attribute' => 'householdMembers',
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
          'should emit error if household doesn\'t exist',
          ->(input) { input.merge(household_id: '0') },
          {
            'message' => "Cannot find Enrollment for household with id '0'",
            'attribute' => 'householdId',
          },
        ],
      ].each do |test_name, input_proc, error_attrs|
        it test_name do
          input = input_proc.call(test_input)
          response, result = post_graphql(input: input) { mutation }

          enrollments = result.dig('data', 'addHouseholdMembersToEnrollment', 'enrollments')
          errors = result.dig('data', 'addHouseholdMembersToEnrollment', 'errors')
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
