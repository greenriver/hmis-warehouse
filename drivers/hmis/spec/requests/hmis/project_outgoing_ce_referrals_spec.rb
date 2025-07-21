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
  let!(:source_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project, client: c1) }

  let!(:target_project) { create(:hmis_hud_project, data_source: ds1, user: u1) }
  let!(:target_opportunity) { create(:hmis_ce_opportunity, data_source: ds1, project: target_project) }

  let!(:outgoing_referral) do
    create(
      :hmis_ce_referral,
      data_source: ds1,
      opportunity: target_opportunity,
      source_enrollment: source_enrollment,
      referred_by: hmis_user,
      referral_origin: 'project',
    )
  end

  let(:query) do
    <<~GRAPHQL
      query GetProjectOutgoingCeReferrals(
        $id: ID!
      ) {
        project(id: $id) {
          id
          outgoingCeReferrals {
            nodes {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'project outgoing_ce_referrals query' do
    context 'when user has can_manage_outgoing_referrals permission' do
      let!(:access_control) do
        create_access_control(
          hmis_user,
          source_project,
          with_permission: [
            :can_view_project,
            :can_manage_outgoing_referrals,
          ],
        )
      end

      it 'resolves outgoing CE referrals successfully' do
        response, result = post_graphql(id: source_project.id) { query }

        expect(response.status).to eq(200), result.inspect
        project_data = result.dig('data', 'project')
        expect(project_data['id']).to eq(source_project.id.to_s)

        outgoing_referrals = project_data.dig('outgoingCeReferrals', 'nodes')
        expect(outgoing_referrals).to be_an(Array)
        expect(outgoing_referrals.size).to eq(1)
        expect(outgoing_referrals.first['id']).to eq(outgoing_referral.id.to_s)
      end
    end

    context 'when user does not have can_manage_outgoing_referrals permission' do
      let!(:access_control) do
        create_access_control(
          hmis_user,
          source_project,
          with_permission: [
            :can_view_project,
          ],
          without_permission: [
            :can_manage_outgoing_referrals,
          ],
        )
      end

      it 'raises access denied error' do
        expect_gql_error(post_graphql(id: source_project.id) { query }, message: 'access denied')
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
