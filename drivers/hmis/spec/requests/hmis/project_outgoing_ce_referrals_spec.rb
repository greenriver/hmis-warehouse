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
  let!(:source_enrollment1) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project) }
  let!(:source_enrollment2) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project) }
  let!(:source_ac) { create_access_control(hmis_user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals]) }

  let!(:target_project1) { create(:hmis_hud_project, data_source: ds1, user: u1) }
  let!(:target_opportunity1) { create(:hmis_ce_opportunity, data_source: ds1, project: target_project1) }
  let!(:outgoing_referral1) { create(:hmis_ce_referral, data_source: ds1, opportunity: target_opportunity1, source_enrollment: source_enrollment1, client: source_enrollment1.client, referral_origin: 'project') }

  let!(:target_project2) { create(:hmis_hud_project, data_source: ds1, user: u1) }
  let!(:target_opportunity2) { create(:hmis_ce_opportunity, data_source: ds1, project: target_project2) }
  let!(:outgoing_referral2) { create(:hmis_ce_referral, data_source: ds1, opportunity: target_opportunity2, source_enrollment: source_enrollment2, client: source_enrollment2.client, referral_origin: 'project') }

  let(:query) do
    <<~GRAPHQL
      query GetProjectOutgoingCeReferrals(
        $id: ID!
      ) {
        project(id: $id) {
          id
          outgoingCeReferrals {
            nodes {
              # summary fields that are always resolved
              id
              status

              # special case summary field that's only resolved when the user has permission to view the client
              client {
                id
                firstName
              }

              # non-summary fields that are not resolved unless the user has full view permission
              clientName

              # access object that indicates whether the user can view full details (and link to) this referral
              access {
                canViewReferralDetails
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
        outgoing_referrals = result.dig('data', 'project', 'outgoingCeReferrals', 'nodes')

        expect(outgoing_referrals).to contain_exactly(
          # Expect to resolve summary-level fields like ID and status, but not details like client name
          a_hash_including(
            'id' => outgoing_referral1.id.to_s,
            'status' => outgoing_referral1.status,
            'client' => nil,
            'clientName' => nil,
            'access' => {
              'canViewReferralDetails' => false,
            },
          ),
          a_hash_including(
            'id' => outgoing_referral2.id.to_s,
            'status' => outgoing_referral2.status,
            'client' => nil,
            'clientName' => nil,
            'access' => {
              'canViewReferralDetails' => false,
            },
          ),
        )
      end

      context 'and the current user can view the client' do
        let!(:source_ac) { create_access_control(hmis_user, source_project, with_permission: [:can_view_project, :can_manage_outgoing_referrals, :can_view_clients, :can_view_client_name]) }

        it 'resolves the client' do
          response, result = post_graphql(id: source_project.id) { query }
          expect(response.status).to eq(200), result.inspect
          outgoing_referrals = result.dig('data', 'project', 'outgoingCeReferrals', 'nodes')

          expect(outgoing_referrals.map { |referral| referral['client'] }).to contain_exactly(
            a_hash_including(
              'id' => source_enrollment1.client.id.to_s,
              'firstName' => source_enrollment1.client.first_name,
            ),
            a_hash_including(
              'id' => source_enrollment2.client.id.to_s,
              'firstName' => source_enrollment2.client.first_name,
            ),
          )
        end
      end
    end

    context 'when the user can view full referral details at a target project' do
      let!(:target_ac) { create_access_control(hmis_user, target_project1, with_permission: [:can_view_project, :can_view_referrals]) }

      it 'resolves full referral details, only for referrals at that project' do
        response, result = post_graphql(id: source_project.id) { query }
        expect(response.status).to eq(200), result.inspect
        outgoing_referrals = result.dig('data', 'project', 'outgoingCeReferrals', 'nodes')

        expect(outgoing_referrals).to include(
          # includes detailed access fields like currentSteps and clientName
          a_hash_including(
            'id' => outgoing_referral1.id.to_s,
            'clientName' => source_enrollment1.client.brief_name,
            'access' => {
              'canViewReferralDetails' => true,
            },
          ),
          a_hash_including(
            'id' => outgoing_referral2.id.to_s,
            'clientName' => nil, # can't view the client name
            'access' => {
              'canViewReferralDetails' => false, # can't link to the referral
            },
          ),
        )
      end
    end

    # todo @martha - test for n+1

    it 'raises access denied error when user does not have can_manage_outgoing_referrals' do
      remove_permissions(source_ac, :can_manage_outgoing_referrals)
      expect_gql_error(post_graphql(id: source_project.id) { query }, message: 'access denied')
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
