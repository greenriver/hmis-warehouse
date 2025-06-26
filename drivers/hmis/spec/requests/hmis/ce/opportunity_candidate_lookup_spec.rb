# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:client) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
  let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, client: client }

  let!(:pool) { create :hmis_ce_match_candidate_pool }
  let!(:opportunity) { create :hmis_ce_opportunity, data_source: ds1, candidate_pool: pool }
  let!(:candidate) { create(:hmis_ce_match_candidate, client: client, candidate_pool: pool) }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  let!(:access_control) do
    create_access_control(hmis_user, ds1)
  end

  describe 'candidateLookup query' do
    let(:query) do
      <<~GRAPHQL
        query GetOpportunityCandidate($opportunityId: ID!, $candidateId: ID!) {
          ceOpportunity(id: $opportunityId) {
            id
            candidateLookup(id: $candidateId) {
              id
              enrollments {
                nodesCount
                nodes {
                  #{scalar_fields(Types::HmisSchema::CeReferralSourceEnrollment)}
                  assessments {
                    id
                    assessmentName
                    assessmentDate
                  }
                }
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        opportunityId: opportunity.id,
        candidateId: candidate.id,
      }
    end

    context 'with enrollments that have different household membership and statuses' do
      let!(:other_hhm) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
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

      it 'correctly returns the enrollment fields' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        enrollments = result.dig('data', 'ceOpportunity', 'candidateLookup', 'enrollments', 'nodes')
        expect(enrollments).to contain_exactly(
          a_hash_including(
            'id' => enrollment.id.to_s,
            'projectName' => enrollment.project.project_name,
            'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
            'householdSize' => 1,
            'otherHouseholdMemberNames' => [],
            'entryDate' => enrollment.entry_date.iso8601,
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
    end

    context 'with candidate pool expressions that refer to CDEs' do
      let!(:fd1) { create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
      # default form definition factory generates cded "fieldOne"
      let!(:cded_field_one) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'fieldOne', form_definition: fd1 }

      let!(:assmt_fd1_new) { create(:hmis_custom_assessment, data_source: ds1, enrollment: enrollment, definition: fd1, assessment_date: 2.weeks.ago) }
      let!(:assmt_fd1_old) { create(:hmis_custom_assessment, data_source: ds1, enrollment: enrollment, definition: fd1, assessment_date: 3.weeks.ago) }

      let!(:fd2) { create(:custom_assessment_with_custom_fields, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
      # custom_assessment_with_custom_fields factory generates cded "custom_question_1"
      let!(:cded_custom_question_1) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'custom_question_1', form_definition: fd2 }

      let!(:assmt_fd2_new) { create(:hmis_custom_assessment, data_source: ds1, enrollment: enrollment, definition: fd2, assessment_date: 2.weeks.ago) }
      let!(:assmt_fd2_old) { create(:hmis_custom_assessment, data_source: ds1, enrollment: enrollment, definition: fd2, assessment_date: 3.weeks.ago) }

      # Update the candidate pool to refer to those cdeds
      let!(:pool) { create :hmis_ce_match_candidate_pool, requirement_expression: "`cde.custom_assessment.fieldOne` = '1'", priority_expression: 'cde.custom_assessment.custom_question_1' }

      it 'returns the latest assessment per definition' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        enrollments = result.dig('data', 'ceOpportunity', 'candidateLookup', 'enrollments', 'nodes')
        expect(enrollments.sole['assessments']).to contain_exactly(
          { 'id' => assmt_fd1_new.id.to_s, 'assessmentName' => fd1.title, 'assessmentDate' => assmt_fd1_new.assessment_date.iso8601 },
          { 'id' => assmt_fd2_new.id.to_s, 'assessmentName' => fd2.title, 'assessmentDate' => assmt_fd2_new.assessment_date.iso8601 },
        )
      end
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
          expect(result.dig('data', 'ceOpportunity', 'candidateLookup', 'enrollments', 'nodesCount')).to eq(41)
        end.to make_database_queries(count: 20..30)
      end
    end

    context 'user does not have can_view_prioritized_client_lists permission' do
      let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_view_prioritized_client_lists) }

      it 'returns an error' do
        expect_gql_error(post_graphql(**variables) { query }, message: 'access denied')
      end
    end

    context 'candidate is not in this opportunitys pool' do
      let!(:other_candidate) { create(:hmis_ce_match_candidate) }

      let(:variables) do
        {
          opportunityId: opportunity.id,
          candidateId: other_candidate.id,
        }
      end

      it 'does not return' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'ceOpportunity', 'candidateLookup')).to be_nil
      end
    end
  end
end
