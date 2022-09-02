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
        mutation CreateEnrollment($input: CreateEnrollmentValues!) {
          createEnrollment(input: { input: $input }) {
            enrollments {
              id
              entryDate
              inProgress
              client {
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
        expect(errors).to be_empty
      end
    end

    describe 'Validity tests' do
      [
        [
          'should emit error if none of the clients are HoH',
          ->(input) { input.merge(household_members: input[:household_members][1..]) },
          'Exactly one client must be head of household',
        ],
        [
          'should emit error if entry date is in the future',
          ->(input) { input.merge(start_date: (Date.today + 1.day).strftime('%Y-%m-%d')) },
          'Entry date cannot be in the future',
        ],
        [
          'should emit error if entry date is in the future',
          ->(input) { input.merge(project_id: '0') },
          'Entry date cannot be in the future',
        ],
      ].each do |test_name, input_proc, error_message|
        it test_name do
          input = input_proc.call(test_input)
          response, result = post_graphql(input: input) { mutation }

          enrollments = result.dig('data', 'createEnrollment', 'enrollments')
          errors = result.dig('data', 'createEnrollment', 'errors')
          expect(response.status).to eq 200
          expect(enrollments).to be_empty
          expect(errors).to contain_exactly(
            include('message' => error_message),
          )
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
