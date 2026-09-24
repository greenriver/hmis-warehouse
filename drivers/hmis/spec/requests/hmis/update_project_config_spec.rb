###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'UpdateProjectConfig Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation UpdateProjectConfig($id: ID!, $input: ProjectConfigInput!) {
        updateProjectConfig(id: $id, input: $input) {
          projectConfig {
            id
            configType
            configOptions
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:project_config) { create(:hmis_project_auto_enter_config, project: p1, data_source: ds1) }

  before(:each) do
    hmis_login(user)
  end

  it 'successfully updates a project config' do
    auto_exit_config = create(:hmis_project_auto_exit_config, project: p1, data_source: ds1, length_of_absence_days: 30)
    response, result = post_graphql(id: auto_exit_config.id, input: { length_of_absence_days: 45 }) { mutation }

    expect(response.status).to eq(200), result.inspect
    expect(JSON.parse(result.dig('data', 'updateProjectConfig', 'projectConfig', 'configOptions'))).to eq('length_of_absence_days' => 45)
    expect(auto_exit_config.reload.length_of_absence_days).to eq(45)
  end

  it 'throws an error when the user does not have access' do
    remove_permissions(access_control, :can_configure_data_collection)
    expect_access_denied(post_graphql(id: project_config.id, input: { config_type: 'AUTO_ENTER' }) { mutation })
  end

  it 'returns a validation error when config type changes' do
    response, result = post_graphql(id: project_config.id, input: { config_type: 'AUTO_EXIT', length_of_absence_days: 30 }) { mutation }

    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateProjectConfig', 'projectConfig')).to be_nil
    expect(result.dig('data', 'updateProjectConfig', 'errors')).to contain_exactly(
      a_hash_including('attribute' => 'configType', 'message' => 'cannot be changed once set'),
    )
  end

  describe 'receivesDirectReferralsFrom' do
    let!(:receiving_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:allowed_sender) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:other_sender) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:ce_config) do
      create(
        :hmis_project_ce_config,
        project: receiving_project,
        receives_direct_referrals: true,
        supports_waitlist_referrals: false,
      )
    end

    before(:each) do
      allow(Hmis::Ce::Match::CandidatePool).to receive(:lock_for_maintenance!).and_yield
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    end

    def stored_allowlist(config)
      JSON.parse(config.reload.config_options)['receives_direct_referrals_from']
    end

    # The whole point of the integer cast. GraphQL sends ID arguments as strings, and enforcement
    # compares with include?(source_project.id), so storing strings would reject every sender.
    it 'stores integers when sent string ids, and enforcement then accepts only the named sender' do
      response, result = post_graphql(id: ce_config.id, input: { receives_direct_referrals_from: [allowed_sender.id.to_s] }) { mutation }

      expect(response.status).to eq(200), result.inspect
      expect(stored_allowlist(ce_config)).to eq([allowed_sender.id])
      expect(receiving_project.receives_direct_ce_referrals_from?(allowed_sender)).to eq(true)
      expect(receiving_project.receives_direct_ce_referrals_from?(other_sender)).to eq(false)
    end

    it 'leaves an existing allowlist untouched when the argument is omitted' do
      ce_config.update!(receives_direct_referrals_from: [allowed_sender.id])

      response, result = post_graphql(id: ce_config.id, input: { supports_waitlist_referrals: true }) { mutation }

      expect(response.status).to eq(200), result.inspect
      expect(stored_allowlist(ce_config)).to eq([allowed_sender.id])
    end

    it 'clears the allowlist when sent an empty array, returning to accepting from all senders' do
      ce_config.update!(receives_direct_referrals_from: [allowed_sender.id])
      expect(receiving_project.receives_direct_ce_referrals_from?(other_sender)).to eq(false)

      response, result = post_graphql(id: ce_config.id, input: { receives_direct_referrals_from: [] }) { mutation }

      expect(response.status).to eq(200), result.inspect
      expect(stored_allowlist(ce_config)).to be_nil
      expect(receiving_project.receives_direct_ce_referrals_from?(other_sender)).to eq(true)
    end

    context 'when the CE config is scoped to an organization' do
      let!(:org) { create(:hmis_hud_organization, data_source: ds1, user: u1) }
      let!(:project_in_org) { create(:hmis_hud_project, data_source: ds1, organization: org, user: u1) }
      let!(:org_ce_config) do
        create(
          :hmis_project_ce_config,
          organization: org,
          receives_direct_referrals: true,
          supports_waitlist_referrals: false,
        )
      end

      it 'round trips the allowlist and enforces it for projects in that organization' do
        response, result = post_graphql(id: org_ce_config.id, input: { receives_direct_referrals_from: [allowed_sender.id.to_s] }) { mutation }

        expect(response.status).to eq(200), result.inspect
        expect(stored_allowlist(org_ce_config)).to eq([allowed_sender.id])
        expect(project_in_org.receives_direct_ce_referrals_from?(allowed_sender)).to eq(true)
        expect(project_in_org.receives_direct_ce_referrals_from?(other_sender)).to eq(false)
      end
    end

    context 'when the CE config is scoped to a project type' do
      let!(:typed_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 4) }
      let!(:typed_ce_config) do
        create(
          :hmis_project_ce_config,
          data_source: ds1,
          project_type: 4,
          receives_direct_referrals: true,
          supports_waitlist_referrals: false,
        )
      end

      it 'round trips the allowlist and enforces it for projects of that type' do
        response, result = post_graphql(id: typed_ce_config.id, input: { receives_direct_referrals_from: [allowed_sender.id.to_s] }) { mutation }

        expect(response.status).to eq(200), result.inspect
        expect(stored_allowlist(typed_ce_config)).to eq([allowed_sender.id])
        expect(typed_project.receives_direct_ce_referrals_from?(allowed_sender)).to eq(true)
        expect(typed_project.receives_direct_ce_referrals_from?(other_sender)).to eq(false)
      end
    end
  end
end
