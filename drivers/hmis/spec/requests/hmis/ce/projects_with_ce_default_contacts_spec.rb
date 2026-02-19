###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'Project CE Default Contacts Query', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query GetProjectCeDefaultContacts($id: ID!) {
        project(id: $id) {
          id
          projectName
          ceDefaultContacts {
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
          ceSwimlanes {
            id
            name
            templateName
            templateIdentifier
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [:can_view_project],
    )
  end

  let!(:project) { create(:hmis_hud_project, data_source: ds1) }
  let!(:ce_config) { create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true, receives_direct_referrals: true) }

  let!(:workflow_template) do
    create(
      :hmis_workflow_definition_template,
      :with_basic_tasks,
      data_source: ds1,
      status: 'published',
      template_type: 'ce_referral',
      identifier: 'ce_workflow',
      name: 'CE Workflow',
    )
  end
  let!(:swimlane1) { create(:hmis_workflow_definition_swimlane, template: workflow_template, name: 'Case Managers') }
  let!(:swimlane2) { create(:hmis_workflow_definition_swimlane, template: workflow_template, name: 'Housing Navigators') }

  let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template_identifier: workflow_template.identifier) }

  before(:each) do
    hmis_login(user)
  end

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  describe 'ceDefaultContacts field' do
    context 'with project-level and global assignments' do
      let!(:user1) { create(:hmis_user, data_source: ds1) }
      let!(:user2) { create(:hmis_user, data_source: ds1) }
      let!(:user3) { create(:hmis_user, data_source: ds1) }

      # Project-level assignments
      let!(:project_assignment1) { create(:hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: project) }
      let!(:project_assignment2) { create(:hmis_ce_default_swimlane_assignment, user: user2, swimlane: swimlane2, owner: project) }

      # Global (data source-level) assignment
      let!(:global_assignment) { create(:hmis_ce_default_swimlane_assignment, user: user3, swimlane: swimlane1, owner: ds1) }

      it 'returns both project-level and global contacts grouped by swimlane' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect

        contacts_by_swimlane = result.dig('data', 'project', 'ceDefaultContacts')
        expect(contacts_by_swimlane.size).to eq(2)

        # Check swimlane1 has both project-level and global contacts
        swimlane1_group = contacts_by_swimlane.find { |g| g['swimlane']['id'] == swimlane1.id.to_s }
        expect(swimlane1_group).to be_present
        expect(swimlane1_group['swimlane']).to include(
          'id' => swimlane1.id.to_s,
          'name' => 'Case Managers',
          'templateName' => 'CE Workflow',
          'templateIdentifier' => 'ce_workflow',
        )
        expect(swimlane1_group['contacts'].size).to eq(2)

        # Verify project-level contact
        project_contact = swimlane1_group['contacts'].find { |c| c['user']['id'] == user1.id.to_s }
        expect(project_contact).to include(
          'user' => { 'id' => user1.id.to_s, 'name' => user1.name },
          'projectId' => project.id.to_s,
          'organizationId' => nil,
          'unitGroupId' => nil,
          'global' => false,
        )

        # Verify global contact
        global_contact = swimlane1_group['contacts'].find { |c| c['user']['id'] == user3.id.to_s }
        expect(global_contact).to include(
          'user' => { 'id' => user3.id.to_s, 'name' => user3.name },
          'projectId' => nil,
          'organizationId' => nil,
          'unitGroupId' => nil,
          'global' => true,
        )

        # Check swimlane2 has only project-level contact
        swimlane2_group = contacts_by_swimlane.find { |g| g['swimlane']['id'] == swimlane2.id.to_s }
        expect(swimlane2_group).to be_present
        expect(swimlane2_group['contacts'].size).to eq(1)
        expect(swimlane2_group['contacts'].first).to include(
          'user' => { 'id' => user2.id.to_s, 'name' => user2.name },
          'projectId' => project.id.to_s,
          'global' => false,
        )
      end
    end
  end

  describe 'ceSwimlanes field' do
    context 'with unit groups using workflow templates' do
      it 'returns all swimlanes from the workflow templates used by this project\'s unit groups, even with no assignees' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect

        swimlanes = result.dig('data', 'project', 'ceSwimlanes')
        expect(swimlanes.size).to eq(2)

        swimlane_ids = swimlanes.map { |s| s['id'] }
        expect(swimlane_ids).to contain_exactly(swimlane1.id.to_s, swimlane2.id.to_s)
      end
    end

    context 'with direct_referral_workflow_template_identifier' do
      let!(:direct_referral_template) do
        create(
          :hmis_workflow_definition_template,
          :with_basic_tasks,
          data_source: ds1,
          status: 'published',
          template_type: 'ce_referral',
          identifier: 'direct_referral_workflow',
          name: 'Direct Referral Workflow',
        )
      end
      let!(:direct_referral_swimlane) { create(:hmis_workflow_definition_swimlane, template: direct_referral_template, name: 'Direct Referral Lane') }

      before do
        unit_group.update!(direct_referral_workflow_template_identifier: direct_referral_template.identifier)
      end

      it 'includes swimlanes from direct referral workflow templates' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect

        swimlanes = result.dig('data', 'project', 'ceSwimlanes')
        swimlane_ids = swimlanes.map { |s| s['id'] }

        # Should include swimlanes from both the regular and direct referral templates
        expect(swimlane_ids).to include(swimlane1.id.to_s, swimlane2.id.to_s, direct_referral_swimlane.id.to_s)
      end
    end
  end

  describe 'query performance' do
    context 'with multiple swimlanes and contacts' do
      let!(:additional_swimlanes) { create_list(:hmis_workflow_definition_swimlane, 10, template: workflow_template) }
      let!(:users) { create_list(:hmis_user, 10, data_source: ds1) }
      let!(:unit_groups) { create_list(:hmis_unit_group, 3, project: project, workflow_template_identifier: workflow_template.identifier) }

      let!(:assignments) do
        ([swimlane1, swimlane2] + additional_swimlanes).flat_map do |swimlane|
          users.sample(3).map do |user|
            create(:hmis_ce_default_swimlane_assignment, user: user, swimlane: swimlane, owner: project)
          end
        end
      end

      it 'avoids N+1 queries' do
        expect do
          response, result = post_graphql(id: project.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'ceDefaultContacts').size).to be > 0
          expect(result.dig('data', 'project', 'ceSwimlanes').size).to be > 0
        end.to make_database_queries(count: 20..30)
      end
    end
  end

  describe 'permissions' do
    context 'when user cannot view project' do
      let!(:ds2) { create(:hmis_data_source) }
      let!(:other_project) { create(:hmis_hud_project, data_source: ds2) }

      it 'returns nil for project' do
        response, result = post_graphql(id: other_project.id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project')).to be_nil
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
