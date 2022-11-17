require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:test_input) do
    {
      project_id: p1.id,
      start_date: Date.today.strftime('%Y-%m-%d'),
      household_members: [
        {
          id: c1.id,
          relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(1).first,
        },
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
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
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

    let(:get_client_query) do
      <<~GRAPHQL
        query GetClient($id: ID!) {
          client(id: $id) {
            enrollments {
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

    it 'should create an enrollment successfully' do
      response, result = post_graphql(input: test_input) { mutation }

      aggregate_failures 'checking response' do
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

        # enrollment should appear on client query
        response, result = post_graphql(id: c1.id) { get_client_query }
        expect(response.status).to eq 200
        client = result.dig('data', 'client')
        expect(client).to be_present
        expect(client.dig('enrollments', 'nodesCount')).to eq(1)
      end
    end

    describe 'In progress tests' do
      it 'should create WIP enrollment' do
        response, result = post_graphql(input: test_input.merge(in_progress: true)) { mutation }
        aggregate_failures 'checking response' do
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
          expect(Hmis::Wip.all).to include(*enrollments.map { |e| have_attributes(project_id: test_input[:project_id], client_id: e['client']['id'].to_i) })
          expect(Hmis::Hud::Enrollment.viewable_by(hmis_user).count).to eq(3)

          # WIP enrollment should appear on client query
          response, result = post_graphql(id: c1.id) { get_client_query }
          expect(response.status).to eq 200
          client = result.dig('data', 'client')
          expect(client).to be_present
          expect(client.dig('enrollments', 'nodesCount')).to eq(1)
        end
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
          ->(input) { input.merge(start_date: (Date.today + 1.week).strftime('%Y-%m-%d')) },
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
          aggregate_failures 'checking response' do
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
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
