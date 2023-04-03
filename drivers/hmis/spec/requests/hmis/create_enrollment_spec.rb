require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:test_input) do
    {
      project_id: p1.id,
      entry_date: Date.yesterday.strftime('%Y-%m-%d'),
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
              #{scalar_fields(Types::HmisSchema::Enrollment)}
              client {
                id
              }
              project {
                id
              }
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    let(:get_client_query) do
      <<~GRAPHQL
        query GetClient($id: ID!) {
          client(id: $id) {
            enrollments(includeInProgress: true) {
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

    it 'should create all household enrollments successfully' do
      response, result = post_graphql(input: test_input) { mutation }
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
        expect(Hmis::Hud::Enrollment.all).to include(
          *enrollments.map do |e|
            have_attributes(
              enrollment_id: be_present,
              household_id: be_present,
              relationship_to_ho_h: be_present,
              entry_date: be_present,
              project_id: nil, # because WIP
              personal_id: Hmis::Hud::Client.find(e['client']['id'].to_i).personal_id,
            )
          end,
        )
        expect(Hmis::Hud::Enrollment.pluck(:household_id).uniq.count).to eq(1)
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

    it 'should throw error if unauthorized' do
      remove_permissions(hmis_user, :can_edit_enrollments)
      response, result = post_graphql(input: test_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        enrollments = result.dig('data', 'createEnrollment', 'enrollments')
        errors = result.dig('data', 'createEnrollment', 'errors')
        expect(enrollments).to be nil
        expect(errors).to be_present
        expect(errors).to contain_exactly(include('type' => 'not_allowed'))
        expect(Hmis::Hud::Enrollment.count).to eq(0)
      end
    end

    describe 'Validity tests' do
      [
        [
          'should emit error if none of the clients are HoH',
          ->(input) { input.merge(household_members: input[:household_members][1..]) },
          {
            fullMessage: 'Exactly one client must be head of household',
            attribute: 'relationshipToHoH',
            severity: :error,
          },
        ],
        [
          'should emit error if entry date is in the future',
          ->(input) { input.merge(entry_date: (Date.today + 1.week).strftime('%Y-%m-%d')) },
          {
            fullMessage: 'Entry date cannot be in the future',
            attribute: 'entryDate',
            severity: :error,
          },
        ],
        [
          'should emit error if project doesn\'t exist',
          ->(input) { input.merge(project_id: '0') },
          {
            fullMessage: 'Project not found',
            severity: :error,
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
            expect(enrollments).to be nil
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
