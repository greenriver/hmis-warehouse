# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:client) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
  let!(:other_hhm) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
  let!(:solo_enrollment) { create :hmis_hud_enrollment, data_source: ds1, client: client }
  let!(:other_hhm_enrollment) { create :hmis_hud_enrollment, data_source: ds1, client: other_hhm }
  let!(:enrollment_with_household) do
    create(
      :hmis_hud_enrollment,
      data_source: ds1,
      client: client,
      household_id: other_hhm_enrollment.household_id,
      relationship_to_hoh: 3,
    )
  end
  let!(:exited_enrollment) { create :hmis_hud_enrollment, data_source: ds1, client: client, entry_date: 1.year.ago, exit_date: 6.weeks.ago }
  # todo @martha - test assessment

  let!(:candidate) { create(:hmis_ce_match_candidate, client: client) }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  let!(:access_control) do
    create_access_control(hmis_user, ds1)
  end

  describe 'GetCeCandidate query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeCandidate($id: ID!) {
          ceCandidate(id: $id) {
            id
            clientId
            enrollments {
              nodesCount
              nodes {
                #{scalar_fields(Types::HmisSchema::CeReferralSourceEnrollment)}
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: candidate.id,
      }
    end

    it 'returns the enrollments' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect
      enrollments = result.dig('data', 'ceCandidate', 'enrollments', 'nodes')
      expect(enrollments).to contain_exactly(
        a_hash_including(
          'id' => solo_enrollment.id.to_s,
          'projectName' => solo_enrollment.project.project_name,
          'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
          'householdSize' => 1,
          'otherHouseholdMemberNames' => [],
          'entryDate' => solo_enrollment.entry_date.iso8601,
          'exitDate' => nil,
          'projectType' => 'ES_NBN',
        ),
        a_hash_including(
          'id' => enrollment_with_household.id.to_s,
          'projectName' => enrollment_with_household.project.project_name,
          'relationshipToHoH' => 'SPOUSE_OR_PARTNER',
          'householdSize' => 2,
          'otherHouseholdMemberNames' => [other_hhm.brief_name],
          'entryDate' => enrollment_with_household.entry_date.iso8601,
          'exitDate' => nil,
          'projectType' => 'ES_NBN',
        ),
        a_hash_including(
          'id' => exited_enrollment.id.to_s,
          'projectName' => exited_enrollment.project.project_name,
          'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
          'householdSize' => 1,
          'otherHouseholdMemberNames' => [],
          'entryDate' => exited_enrollment.entry_date.iso8601,
          'exitDate' => exited_enrollment.exit_date.iso8601,
          'projectType' => 'ES_NBN',
        ),
      )
    end

    context 'with many enrollments' do
      before do
        40.times do
          create :hmis_hud_enrollment, data_source: ds1, client: client
        end
      end

      it 'queries a reasonable amount' do
        expect do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceCandidate', 'enrollments', 'nodesCount')).to eq(43)
        end.to make_database_queries(count: 20..30)
      end
    end
  end
end
