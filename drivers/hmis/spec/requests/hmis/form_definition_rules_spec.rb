###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  before(:each) do
    hmis_login(user)
  end

  describe 'Form definition rule application (Assessment form)' do
    let(:form_role) { 'INTAKE' }
    let(:base_items) do
      [
        {
          'type': 'STRING',
          'link_id': 'field-project-type-2',
        },
        {
          'type': 'STRING',
          'link_id': 'field-2',
        },
      ]
    end

    let(:query) do
      <<~GRAPHQL
        query GetAssessmentFormDefinition($projectId: ID!, $role: AssessmentRole, $assessmentDate: ISO8601Date) {
          assessmentFormDefinition(projectId: $projectId, role: $role, assessmentDate: $assessmentDate) {
            #{form_definition_fragment}
          }
        }
      GRAPHQL
    end

    def query_form_definition_items(assessment_date: nil)
      response, result = post_graphql({ project_id: p1.id.to_s, role: form_role, assessment_date: assessment_date }) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'assessmentFormDefinition', 'definition', 'item', 0, 'item')
    end

    def assign_rule(rule: nil, custom_rule: nil)
      base_items[0]['rule'] = rule if rule
      base_items[0]['custom_rule'] = custom_rule if custom_rule
      Hmis::Form::Definition.
        where(role: form_role).
        update_all(definition: { 'item' => [{ 'type': 'GROUP', 'link_id': 'group-1', 'item': base_items }] })
    end

    describe 'form definition with projectType rule' do
      let(:project_type) { 5 }
      before(:each) { assign_rule(rule: { variable: 'projectType', operator: 'EQUAL', value: project_type }) }
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with matches' do
        before(:each) { p1.update!(project_type: project_type) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with projectType custom_rule' do
      let(:project_type) { 5 }
      before(:each) do
        assign_rule(
          custom_rule: { operator: 'ANY', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type }] },
        )
      end
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with match' do
        before(:each) { p1.update!(project_type: project_type) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with projectType rule AND projectType custom_rule' do
      let(:project_type) { 5 }
      let(:project_type_2) { 6 }
      before(:each) do
        assign_rule(
          rule: { operator: 'ANY', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type }] },
          custom_rule: { operator: 'ANY', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type_2 }] },
        )
      end
      it 'excludes filtered items (neither rules match)' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with match on HUD Rule (and no match on Custom rule)' do
        before(:each) { p1.update!(project_type: project_type) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
      describe 'with match on custom rule (and no match on HUD rule)' do
        before(:each) { p1.update!(project_type: project_type_2) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with projectFunders rule' do
      let(:funder) { 1234 }
      before(:each) { assign_rule(rule: { variable: 'projectFunders', operator: 'INCLUDE', value: funder }) }
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with matches' do
        before(:each) { create :hmis_hud_funder, data_source: ds1, project: p1, funder: funder }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
      describe 'with active date specified' do
        before(:each) { create :hmis_hud_funder, start_date: 2.years.ago, end_date: 1.year.ago, data_source: ds1, project: p1, funder: funder }
        it 'excludes filtered items if funder is not currently active' do
          expect(query_form_definition_items.size).to eq(base_items.size - 1)
        end
        it 'excludes filtered items if funder was NOT active at specified date' do
          expect(query_form_definition_items(assessment_date: 6.months.ago).size).to eq(base_items.size - 1)
        end
        it 'includes all items if funder WAS active at specified date' do
          expect(query_form_definition_items(assessment_date: 18.months.ago).size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with projectOtherFunders rule' do
      let(:other_funder) { '123XYZ' }
      before(:each) { assign_rule(rule: { variable: 'projectOtherFunders', operator: 'INCLUDE', value: other_funder }) }
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with matches' do
        before(:each) { create :hmis_hud_funder, data_source: ds1, project: p1, other_funder: other_funder }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with all rule' do
      let(:project_type) { 5 }
      let(:funder) { 1234 }
      before(:each) do
        assign_rule(rule:
          {
            operator: 'ALL',
            parts: [
              { variable: 'projectType', operator: 'EQUAL', value: project_type },
              { variable: 'projectFunders', operator: 'INCLUDE', value: funder },
            ],
          })
      end
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with partial match' do
        before(:each) { p1.update!(project_type: project_type) }
        it 'excludes filtered items' do
          expect(query_form_definition_items.size).to eq(base_items.size - 1)
        end
      end
      describe 'with complete match' do
        before(:each) do
          p1.update!(project_type: project_type)
          create :hmis_hud_funder, data_source: ds1, project: p1, funder: funder
        end
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with any rule' do
      let(:project_type) { 5 }
      let(:funder) { 1234 }
      before(:each) do
        assign_rule(rule:
          {
            operator: 'ANY',
            parts: [
              { variable: 'projectType', operator: 'EQUAL', value: project_type },
              { variable: 'projectFunders', operator: 'INCLUDE', value: funder },
            ],
          })
      end
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with partial match' do
        before(:each) { p1.update!(project_type: project_type) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end
  end

  describe 'Form definition Project rule application (Enrollment form)' do
    let(:form_role) { 'ENROLLMENT' }
    let(:items_with_rule) do
      [
        {
          'type': 'STRING',
          'link_id': 'field-project-type-2',
          'rule': { variable: 'projectType', operator: 'EQUAL', value: 12 },
        },
        {
          'type': 'STRING',
          'link_id': 'field-2',
        },
      ]
    end

    def apply_items
      Hmis::Form::Definition.
        where(role: form_role).
        update_all(definition: { 'item' => [{ 'type': 'GROUP', 'link_id': 'group-1', 'item': items_with_rule }] })
    end

    let(:query) do
      <<~GRAPHQL
        query recordFormDefinition($projectId: ID, $role: RecordFormRole!) {
          recordFormDefinition(projectId: $projectId, role: $role) {
            #{form_definition_fragment}
          }
        }
      GRAPHQL
    end

    def query_form_definition_items
      response, result = post_graphql({ project_id: p1.id.to_s, role: form_role }) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'recordFormDefinition', 'definition', 'item', 0, 'item')
    end

    describe 'applies projectType rule' do
      before(:each) { apply_items }
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(items_with_rule.size - 1)
      end
      describe 'with matches' do
        before(:each) { p1.update!(project_type: 12) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(items_with_rule.size)
        end
      end
    end
  end

  describe 'Form definition Project rule application (resolved on Assessment lookup)' do
    let(:items_with_rule) do
      [
        {
          'type': 'STRING',
          'link_id': 'field-project-type-2',
          'rule': { variable: 'projectType', operator: 'EQUAL', value: 12 },
        },
        {
          'type': 'STRING',
          'link_id': 'field-2',
        },
      ]
    end

    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let!(:assessment) do
      a1 = create(:hmis_custom_assessment, client: c1, enrollment: e1, data_source: ds1)
      a1.form_processor.definition.update(definition: { 'item' => [{ 'type': 'GROUP', 'link_id': 'group-1', 'item': items_with_rule }] })
      a1
    end

    let(:query) do
      <<~GRAPHQL
        query GetAssessment($id: ID!) {
          assessment(id: $id) {
            id
            definition {
              #{form_definition_fragment}
            }
          }
        }
      GRAPHQL
    end

    def query_form_definition_items
      response, result = post_graphql({ id: assessment.id.to_s }) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'assessment', 'definition', 'definition', 'item', 0, 'item')
    end

    describe 'applies projectType rule' do
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(items_with_rule.size - 1)
      end
      describe 'with matches' do
        before(:each) { p1.update!(project_type: 12) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(items_with_rule.size)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
