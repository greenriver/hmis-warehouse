###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ceSwimlanes Query', type: :request do
  include_context 'hmis base setup'

  subject(:query) do
    <<~GRAPHQL
      query GetCeSwimlanes {
        ceSwimlanes {
          id
          name
          templateName
          templateIdentifier
          taskNames
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

  context 'with published CE workflow templates' do
    let!(:ce_template_1) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral', name: 'CE Workflow 1', identifier: 'ce_workflow_1') }
    let!(:ce_template_2) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral', name: 'CE Workflow 2', identifier: 'ce_workflow_2') }

    let!(:swimlane_1a) { create(:hmis_workflow_definition_swimlane, template: ce_template_1, name: 'Case Managers') }
    let!(:swimlane_1b) { create(:hmis_workflow_definition_swimlane, template: ce_template_1, name: 'Housing Navigators') }
    let!(:swimlane_2a) { create(:hmis_workflow_definition_swimlane, template: ce_template_2, name: 'Assessment Team') }

    let!(:task1) { create(:hmis_workflow_definition_user_task, template: ce_template_1, swimlane: swimlane_1a, name: 'Initial Review') }
    let!(:task2) { create(:hmis_workflow_definition_user_task, template: ce_template_1, swimlane: swimlane_1a, name: 'Follow-up') }
    let!(:task3) { create(:hmis_workflow_definition_user_task, template: ce_template_1, swimlane: swimlane_1b, name: 'Housing Search') }
    let!(:task4) { create(:hmis_workflow_definition_user_task, template: ce_template_2, swimlane: swimlane_2a, name: 'Assessment') }

    it 'returns all swimlanes from published CE templates' do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect

      swimlanes = result.dig('data', 'ceSwimlanes')
      expect(swimlanes.size).to eq(3)

      # Verify swimlane details
      expect(swimlanes).to contain_exactly(
        a_hash_including(
          'id' => swimlane_1a.id.to_s,
          'name' => 'Case Managers',
          'templateName' => 'CE Workflow 1',
          'templateIdentifier' => 'ce_workflow_1',
          'taskNames' => match_array(['Initial Review', 'Follow-up']),
        ),
        a_hash_including(
          'id' => swimlane_1b.id.to_s,
          'name' => 'Housing Navigators',
          'templateName' => 'CE Workflow 1',
          'templateIdentifier' => 'ce_workflow_1',
          'taskNames' => ['Housing Search'],
        ),
        a_hash_including(
          'id' => swimlane_2a.id.to_s,
          'name' => 'Assessment Team',
          'templateName' => 'CE Workflow 2',
          'templateIdentifier' => 'ce_workflow_2',
          'taskNames' => ['Assessment'],
        ),
      )
    end
  end

  context 'with draft templates' do
    let!(:draft_template) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'draft', template_type: 'ce_referral') }
    let!(:draft_swimlane) { create(:hmis_workflow_definition_swimlane, template: draft_template, name: 'Draft Swimlane') }

    it 'excludes swimlanes from draft templates' do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect

      swimlanes = result.dig('data', 'ceSwimlanes')
      swimlane_ids = swimlanes.map { |s| s['id'] }

      expect(swimlane_ids).not_to include(draft_swimlane.id.to_s)
    end
  end

  context 'with templates from different data sources' do
    let!(:ds2) { create(:hmis_data_source) }
    let!(:other_ds_template) { create(:hmis_workflow_definition_template, data_source: ds2, status: 'published', template_type: 'ce_referral') }
    let!(:other_ds_swimlane) { create(:hmis_workflow_definition_swimlane, template: other_ds_template, name: 'Other DS Swimlane') }

    it 'excludes swimlanes from templates not viewable by the user' do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect

      swimlanes = result.dig('data', 'ceSwimlanes')
      swimlane_ids = swimlanes.map { |s| s['id'] }

      expect(swimlane_ids).not_to include(other_ds_swimlane.id.to_s)
    end
  end

  describe 'distinct swimlanes' do
    context 'when swimlane name appears in multiple templates' do
      let!(:template_1) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral', identifier: 'template_1') }
      let!(:template_2) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral', identifier: 'template_2') }
      let!(:swimlane_1) { create(:hmis_workflow_definition_swimlane, template: template_1, name: 'Case Managers') }
      let!(:swimlane_2) { create(:hmis_workflow_definition_swimlane, template: template_2, name: 'Case Managers') }

      it 'returns both swimlanes as distinct records' do
        response, result = post_graphql { query }
        expect(response.status).to eq(200), result.inspect

        swimlanes = result.dig('data', 'ceSwimlanes')
        case_manager_swimlanes = swimlanes.select { |s| s['name'] == 'Case Managers' }

        expect(case_manager_swimlanes.size).to eq(2)
        expect(case_manager_swimlanes.map { |s| s['id'] }).to contain_exactly(swimlane_1.id.to_s, swimlane_2.id.to_s)
        expect(case_manager_swimlanes.map { |s| s['templateIdentifier'] }).to contain_exactly('template_1', 'template_2')
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
