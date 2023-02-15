require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, user: u1 }

  let(:test_input) do
    {
      household_id: enrollment.household_id,
      start_date: Date.today.strftime('%Y-%m-%d'),
      household_members: [
        {
          id: c2.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(2).first,
        },
        {
          id: c3.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(3).first,
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
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
      hmis_login(user)
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
            #{error_fields}
          }
        }
      GRAPHQL
    end

    it 'should add members to an enrollment correctly' do
      response, result = post_graphql(input: test_input) { mutation }

      aggregate_failures 'checking response' do
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
    end

    it 'should add members to an in-progress enrollment correctly' do
      enrollment.save_in_progress

      response, result = post_graphql(input: test_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        enrollments = result.dig('data', 'addHouseholdMembersToEnrollment', 'enrollments')
        errors = result.dig('data', 'addHouseholdMembersToEnrollment', 'errors')
        expect(errors).to be_empty
        expect(enrollments).to be_present
        expect(enrollments.count).to eq(2)
        expect(Hmis::Hud::Enrollment.count).to eq(3)
        expect(Hmis::Hud::Enrollment.in_progress.count).to eq(3)
      end

      # change enrollment back to non-WIP again
      enrollment.project = p1
      enrollment.save_not_in_progress
    end

    describe 'Validity tests' do
      [
        [
          'should emit error if trying to add HoH member when one already exists',
          ->(input) do
            input[:household_members][0][:relationship_to_ho_h] = Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(1).first
            input
          end,
          {
            fullMessage: 'Enrollment already has a Head of Household designated',
            severity: :error,
            type: :invalid,
          },
        ],
        [
          'should emit error if entry date is in the future',
          ->(input) { input.merge(start_date: (Date.today + 1.week).strftime('%Y-%m-%d')) },
          {
            fullMessage: 'Entry date cannot be in the future',
            severity: :error,
            type: :out_of_range,
          },
        ],
        [
          'should emit error if household doesn\'t exist',
          ->(input) { input.merge(household_id: '0') },
          {
            fullMessage: "Cannot find Enrollment for household with id '0'",
            severity: :error,
            type: :invalid,
          },
        ],
      ].each do |test_name, input_proc, error_attrs|
        it test_name do
          input = input_proc.call(test_input)
          response, result = post_graphql(input: input) { mutation }

          enrollments = result.dig('data', 'addHouseholdMembersToEnrollment', 'enrollments')
          errors = result.dig('data', 'addHouseholdMembersToEnrollment', 'errors')

          aggregate_failures 'checking response' do
            expect(response.status).to eq 200
            expect(enrollments).to be_nil
            expect(errors).to contain_exactly(
              include(**error_attrs.transform_keys(&:to_s).transform_values(&:to_s)),
            )
          end
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
