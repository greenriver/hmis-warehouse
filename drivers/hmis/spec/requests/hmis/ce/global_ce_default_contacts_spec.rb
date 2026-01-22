###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'globalCeDefaultContacts Query', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query GetGlobalCeDefaultContacts {
        globalCeDefaultContacts {
          swimlane {
            id
            name
            templateName
            templateIdentifier
          }
          contacts {
            id
            user {
              id
              name
            }
            projectId
            organizationId
            unitGroupId
            global
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [:can_view_project, :can_administrate_coordinated_entry],
    )
  end

  before(:each) do
    hmis_login(user)
  end

  context 'with global default contacts' do
    let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral', name: 'CE Workflow', identifier: 'ce_workflow') }
    let!(:swimlane1) { create(:hmis_workflow_definition_swimlane, template: workflow_template, name: 'Case Managers') }
    let!(:swimlane2) { create(:hmis_workflow_definition_swimlane, template: workflow_template, name: 'Housing Navigators') }
    let!(:swimlane3) { create(:hmis_workflow_definition_swimlane, template: workflow_template, name: 'Assessment Team') }

    let!(:user1) { create(:hmis_user, data_source: ds1) }
    let!(:user2) { create(:hmis_user, data_source: ds1) }
    let!(:user3) { create(:hmis_user, data_source: ds1) }

    let!(:assignment1) { create(:hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: ds1) }
    let!(:assignment2) { create(:hmis_ce_default_swimlane_assignment, user: user2, swimlane: swimlane1, owner: ds1) }
    let!(:assignment3) { create(:hmis_ce_default_swimlane_assignment, user: user3, swimlane: swimlane2, owner: ds1) }

    # cruft: project-level assignment is not returned
    let!(:project_assignment) { create(:hmis_ce_default_swimlane_assignment, user: user2, swimlane: swimlane1, owner: p1) }

    # cruft: other data source assignment is not returned
    let!(:ds2) { create(:hmis_data_source) }
    let!(:other_template) { create(:hmis_workflow_definition_template, data_source: ds2, status: 'published', template_type: 'ce_referral') }
    let!(:other_swimlane) { create(:hmis_workflow_definition_swimlane, template: other_template, name: 'Other DS Swimlane') }
    let!(:other_user) { create(:hmis_user, data_source: ds2) }
    let!(:other_assignment) { create(:hmis_ce_default_swimlane_assignment, user: other_user, swimlane: other_swimlane, owner: ds2) }

    it 'returns global default contacts grouped by swimlane' do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect

      groups = result.dig('data', 'globalCeDefaultContacts')
      expect(groups.size).to eq(2)

      # Verify swimlane1 contacts
      swimlane1_group = groups.find { |g| g['swimlane']['id'] == swimlane1.id.to_s }
      expect(swimlane1_group).to be_present
      expect(swimlane1_group['swimlane']).to include(
        'id' => swimlane1.id.to_s,
        'name' => 'Case Managers',
        'templateName' => 'CE Workflow',
        'templateIdentifier' => 'ce_workflow',
      )
      expect(swimlane1_group['contacts'].size).to eq(2)
      expect(swimlane1_group['contacts']).to all(
        include('global' => true, 'projectId' => nil, 'organizationId' => nil, 'unitGroupId' => nil),
      )
      expect(swimlane1_group['contacts'].map { |c| c['user']['id'] }).to contain_exactly(user1.id.to_s, user2.id.to_s)

      # Verify swimlane2 contacts
      swimlane2_group = groups.find { |g| g['swimlane']['id'] == swimlane2.id.to_s }
      expect(swimlane2_group).to be_present
      expect(swimlane2_group['swimlane']['name']).to eq('Housing Navigators')
      expect(swimlane2_group['contacts'].size).to eq(1)
      expect(swimlane2_group['contacts'].first['user']['id']).to eq(user3.id.to_s)
      expect(swimlane2_group['contacts'].first['global']).to eq(true)
    end
  end

  describe 'query performance' do
    context 'with multiple swimlanes and contacts' do
      let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral') }
      let!(:swimlanes) { create_list(:hmis_workflow_definition_swimlane, 5, template: workflow_template) }
      let!(:users) { create_list(:hmis_user, 10, data_source: ds1) }

      let!(:assignments) do
        swimlanes.flat_map do |swimlane|
          users.sample(3).map do |user|
            create(:hmis_ce_default_swimlane_assignment, user: user, swimlane: swimlane, owner: ds1)
          end
        end
      end

      it 'avoids N+1 queries' do
        expect do
          response, result = post_graphql { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'globalCeDefaultContacts').size).to be > 0
        end.to make_database_queries(count: 5..15)
      end
    end
  end

  describe 'permissions' do
    context 'when user lacks can_administrate_coordinated_entry permission' do
      before do
        remove_permissions(access_control, :can_administrate_coordinated_entry)
      end

      it 'denies access' do
        expect_access_denied(post_graphql { query })
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
