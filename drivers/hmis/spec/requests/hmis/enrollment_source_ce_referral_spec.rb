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
  let!(:client) { create(:hmis_hud_client_complete, data_source: ds1) }
  let!(:source_enrollment) { create(:hmis_hud_enrollment, client: client, data_source: ds1, project: source_project) }

  let!(:target_project) { create(:hmis_hud_project, data_source: ds1, user: u1) }
  let!(:target_enrollment) { create(:hmis_hud_enrollment, client: client, data_source: ds1, project: target_project) }

  let!(:ce_referral) do
    create(
      :hmis_ce_referral,
      data_source: ds1,
      source_enrollment: source_enrollment,
      target_enrollment: target_enrollment,
      project: target_project,
      client: client,
      referral_origin: Hmis::Ce::Referral::DIRECT_SEND_ORIGIN,
    )
  end

  let(:query) do
    <<~GRAPHQL
      query GetEnrollment($id: ID!) {
        enrollment(id: $id) {
          id
          sourceCeReferral {
            # summary fields that should always be resolved
            id
            status

            # access object that indicates user permissions
            access {
              canViewReferralDetails
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'enrollment sourceCeReferral query' do
    context 'when user has enrollment access' do
      let!(:access_control) { create_access_control(hmis_user, target_project, with_permission: [:can_view_project, :can_view_enrollment_details]) }

      it 'resolves source CE referral' do
        response, result = post_graphql(id: target_enrollment.id) { query }
        expect(response.status).to eq(200), result.inspect

        referral_data = result.dig('data', 'enrollment', 'sourceCeReferral')

        # Should resolve summary fields
        expect(referral_data).to include(
          'id' => ce_referral.id.to_s,
          'status' => ce_referral.status,
        )

        # Should indicate no full referral access
        expect(referral_data['access']).to include(
          'canViewReferralDetails' => false,
        )
      end

      context 'when enrollment did not come from a CE referral' do
        let!(:enrollment_without_referral) { create(:hmis_hud_enrollment, data_source: ds1, project: target_project) }

        it 'returns null for sourceCeReferral' do
          response, result = post_graphql(id: enrollment_without_referral.id) { query }
          expect(response.status).to eq(200), result.inspect

          referral_data = result.dig('data', 'enrollment', 'sourceCeReferral')
          expect(referral_data).to be_nil
        end
      end
    end

    context 'when user has both enrollment and full referral access' do
      let!(:access_control) { create_access_control(hmis_user, target_project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_view_referrals]) }

      it 'resolves source CE referral with full access' do
        response, result = post_graphql(id: target_enrollment.id) { query }
        expect(response.status).to eq(200), result.inspect

        referral_data = result.dig('data', 'enrollment', 'sourceCeReferral')

        # Should resolve summary fields
        expect(referral_data).to include(
          'id' => ce_referral.id.to_s,
          'status' => ce_referral.status,
        )

        # Should indicate full referral access
        expect(referral_data['access']).to include(
          'canViewReferralDetails' => true,
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
