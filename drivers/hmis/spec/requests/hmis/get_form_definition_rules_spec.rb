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

  before(:each) do
    hmis_login(user)
  end

  describe 'Conditional fields' do
    let(:form_role) { 'UPDATE' }
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
        query GetFormDefinition($projectId: ID, $role: FormRole!) {
          getFormDefinition(projectId: $projectId, role: $role) {
            #{form_definition_fragment}
          }
        }
      GRAPHQL
    end

    def query_form_definition_items
      _, result = post_graphql({ project_id: p1.id.to_s, role: form_role }) { query }
      result.dig('data', 'getFormDefinition', 'definition', 'item', 0, 'item')
    end

    def assign_rule(rule)
      base_items[0]['rule'] = rule
      Hmis::Form::Definition
        .where(role: form_role)
        .update_all(definition: { 'item' => [{ 'type': 'GROUP', 'link_id': 'group-1', 'item': base_items }] })
    end

    describe 'form definition with projectType rule' do
      let(:project_type) { '5' }
      before(:each) { assign_rule({ variable: 'projectType', operator: 'EQUAL', value: project_type }) }
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

    describe 'form definition with projectFunderIds rule' do
      let(:funder_id) { '1234' }
      before(:each) { assign_rule({ variable: 'projectFunderIds', operator: 'INCLUDE', value: funder_id }) }
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(base_items.size - 1)
      end
      describe 'with matches' do
        before(:each) { create :hmis_hud_funder, data_source: ds1, project: p1, funder_id: funder_id }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with projectOtherFunders rule' do
      let(:other_funder) { '123XYZ' }
      before(:each) { assign_rule({ variable: 'projectOtherFunders', operator: 'INCLUDE', value: other_funder }) }
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
      let(:project_type) { '5' }
      let(:funder_id) { '1234' }
      before(:each) do
        assign_rule(
          {
            operator: 'ALL',
            parts: [
              { variable: 'projectType', operator: 'EQUAL', value: project_type },
              { variable: 'projectFunderIds', operator: 'INCLUDE', value: funder_id },
            ],
          },
        )
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
          create :hmis_hud_funder, data_source: ds1, project: p1, funder_id: funder_id
        end
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(base_items.size)
        end
      end
    end

    describe 'form definition with any rule' do
      let(:project_type) { '5' }
      let(:funder_id) { '1234' }
      before(:each) do
        assign_rule(
          {
            operator: 'ANY',
            parts: [
              { variable: 'projectType', operator: 'EQUAL', value: project_type },
              { variable: 'projectFunderIds', operator: 'INCLUDE', value: funder_id },
            ],
          },
        )
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
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
