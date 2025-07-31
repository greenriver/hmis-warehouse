###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  let!(:source_project) { create(:hmis_hud_project, data_source: ds1, user: u1) }
  let!(:client1) { create(:hmis_hud_client_complete, data_source: ds1) }
  let!(:source_enrollment1) { create(:hmis_hud_enrollment, client: client1, data_source: ds1, project: source_project) }
  let!(:client2) { create(:hmis_hud_client_complete, data_source: ds1) }
  let!(:source_enrollment2) { create(:hmis_hud_enrollment, client: client2, data_source: ds1, project: source_project) }
  let!(:source_ac) { create_access_control(hmis_user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals]) }

  let!(:target_project1) { create(:hmis_hud_project, data_source: ds1, user: u1) }
  let!(:target_opportunity1) { create(:hmis_ce_opportunity, data_source: ds1, project: target_project1) }
  let!(:direct_referral1) { create(:hmis_ce_referral, data_source: ds1, opportunity: target_opportunity1, source_enrollment: source_enrollment1, client: source_enrollment1.client, referral_origin: Hmis::Ce::Referral::DIRECT_SEND_ORIGIN) }

  let!(:target_project2) { create(:hmis_hud_project, data_source: ds1, user: u1) }
  let!(:target_opportunity2) { create(:hmis_ce_opportunity, data_source: ds1, project: target_project2) }
  let!(:direct_referral2) { create(:hmis_ce_referral, data_source: ds1, opportunity: target_opportunity2, source_enrollment: source_enrollment2, client: source_enrollment2.client, referral_origin: Hmis::Ce::Referral::DIRECT_SEND_ORIGIN) }

  let(:query) do
    <<~GRAPHQL
      query GetProjectOutgoingDirectCeReferrals(
        $id: ID!
      ) {
        project(id: $id) {
          id
          outgoingDirectCeReferrals {
            nodesCount
            nodes {
              # summary fields that are always resolved
              id
              status
              sourceEnrollmentId
              clientId

              # special case summary field that is resolved when the user has permission to view the client
              clientName

              # non-summary fields that are not resolved unless the user has full view permission
              clientAge
              client {
                id
                firstName
              }

              # access object that indicates user permissions
              access {
                canViewReferralDetails
                canViewSourceEnrollmentDetails
              }
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'project outgoing_ce_referrals query' do
    context 'when the user can manage outgoing referrals, but not view full referrals' do
      it 'resolves outgoing referrals with summary-level data' do
        response, result = post_graphql(id: source_project.id) { query }
        expect(response.status).to eq(200), result.inspect
        outgoing_referrals = result.dig('data', 'project', 'outgoingDirectCeReferrals', 'nodes')

        expect(outgoing_referrals).to contain_exactly(
          # Expect to resolve summary-level fields like ID and status, but not details like clientAge
          a_hash_including(
            'id' => direct_referral1.id.to_s,
            'status' => direct_referral1.status,
            'clientName' => "Client #{source_enrollment1.client.id}",
            'sourceEnrollmentId' => source_enrollment1.id.to_s,
            'client' => nil,
            'clientAge' => nil,
            'access' => {
              'canViewReferralDetails' => false,
              'canViewSourceEnrollmentDetails' => false,
            },
          ),
          a_hash_including(
            'id' => direct_referral2.id.to_s,
            'status' => direct_referral2.status,
            'clientName' => "Client #{source_enrollment2.client.id}",
            'sourceEnrollmentId' => source_enrollment2.id.to_s,
            'client' => nil,
            'clientAge' => nil,
            'access' => {
              'canViewReferralDetails' => false,
              'canViewSourceEnrollmentDetails' => false,
            },
          ),
        )
      end

      context 'and the current user can view client names' do
        let!(:source_ac) { create_access_control(hmis_user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals, :can_view_clients, :can_view_client_name]) }

        it 'resolves the client name' do
          response, result = post_graphql(id: source_project.id) { query }
          expect(response.status).to eq(200), result.inspect
          outgoing_referrals = result.dig('data', 'project', 'outgoingDirectCeReferrals', 'nodes')

          expect(outgoing_referrals).to contain_exactly(
            a_hash_including(
              'id' => direct_referral1.id.to_s,
              'clientName' => source_enrollment1.client.brief_name,
            ),
            a_hash_including(
              'id' => direct_referral2.id.to_s,
              'clientName' => source_enrollment2.client.brief_name,
            ),
          )
        end
      end

      context 'and the current user can view enrollment details in the source project' do
        let!(:source_ac) { create_access_control(hmis_user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals, :can_view_enrollment_details]) }

        it 'resolves the access object correctly' do
          response, result = post_graphql(id: source_project.id) { query }
          expect(response.status).to eq(200), result.inspect
          outgoing_referrals = result.dig('data', 'project', 'outgoingDirectCeReferrals', 'nodes')

          expect(outgoing_referrals).to contain_exactly(
            a_hash_including(
              'id' => direct_referral1.id.to_s,
              'access' => {
                'canViewReferralDetails' => false,
                'canViewSourceEnrollmentDetails' => true,
              },
            ),
            a_hash_including(
              'id' => direct_referral2.id.to_s,
              'access' => {
                'canViewReferralDetails' => false,
                'canViewSourceEnrollmentDetails' => true,
              },
            ),
          )
        end
      end
    end

    context 'when the user can view full referral details at a target project' do
      let!(:target_ac) { create_access_control(hmis_user, target_project1, with_permission: [:can_view_project, :can_view_referrals]) }
      let!(:source_ac) { create_access_control(hmis_user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals, :can_view_clients, :can_view_client_name]) }

      it 'resolves full referral details, only for referrals at that project' do
        response, result = post_graphql(id: source_project.id) { query }
        expect(response.status).to eq(200), result.inspect
        outgoing_referrals = result.dig('data', 'project', 'outgoingDirectCeReferrals', 'nodes')

        expect(outgoing_referrals).to include(
          # for the referral in the project the user has permissions on, include detailed access fields like currentSteps and clientName
          a_hash_including(
            'id' => direct_referral1.id.to_s,
            'clientName' => source_enrollment1.client.brief_name,
            'clientAge' => source_enrollment1.client.age,
            'client' => a_hash_including(
              'firstName' => source_enrollment1.client.first_name,
            ),
            'access' => {
              'canViewReferralDetails' => true,
              'canViewSourceEnrollmentDetails' => false,
            },
          ),
          # for the other project, can't view client name or other referral details
          a_hash_including(
            'id' => direct_referral2.id.to_s,
            'clientName' => source_enrollment2.client.brief_name,
            'client' => nil,
            'clientAge' => nil,
            'access' => {
              'canViewReferralDetails' => false,
              'canViewSourceEnrollmentDetails' => false,
            },
          ),
        )
      end
    end

    context 'with waitlist referrals whose source enrollment is from this project' do
      # Create a 'waitlist' as opposed to 'direct' referral. It should NOT be included in the query results
      let!(:source_enrollment3) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project) }
      let!(:target_opportunity3) { create(:hmis_ce_opportunity, data_source: ds1, project: target_project1) }
      let!(:waitlist_referral) { create(:hmis_ce_referral, data_source: ds1, opportunity: target_opportunity3, source_enrollment: source_enrollment3, referral_origin: Hmis::Ce::Referral::WAITLIST_ORIGIN) }

      it 'does not include waitlist referral in the outgoing referrals query' do
        response, result = post_graphql(id: source_project.id) { query }
        expect(response.status).to eq(200), result.inspect
        outgoing_referral_ids = result.dig('data', 'project', 'outgoingDirectCeReferrals', 'nodes').map { |referral| referral['id'] }

        expect(outgoing_referral_ids).to include(direct_referral1.id.to_s, direct_referral2.id.to_s)
        expect(outgoing_referral_ids).not_to include(waitlist_referral.id.to_s)
      end
    end

    context 'with many referrals' do
      let!(:referrals) do
        20.times do
          enrollment = create(:hmis_hud_enrollment, data_source: ds1, project: source_project)
          create(:hmis_ce_referral, data_source: ds1, source_enrollment: enrollment, referral_origin: Hmis::Ce::Referral::DIRECT_SEND_ORIGIN)
        end
      end

      it 'does not create n+1 query' do
        expect do
          response, result = post_graphql(id: source_project.id) { query }
          expect(response.status).to eq(200), result.inspect

          expect(result.dig('data', 'project', 'outgoingDirectCeReferrals', 'nodesCount')).to eq(22)
        end.to make_database_queries(count: 25..35)
      end
    end

    it 'raises access denied error when user does not have can_manage_outgoing_referrals' do
      remove_permissions(source_ac, :can_manage_outgoing_referrals)
      expect_gql_error(post_graphql(id: source_project.id) { query }, message: 'access denied')
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
