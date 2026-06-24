###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  include_context 'hmis json forms seed'

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let!(:assessment) { create :hmis_form_definition, identifier: 'test-custom-assessment', role: :CUSTOM_ASSESSMENT, data_source: ds1 }
  let!(:assessment_rule) { create :hmis_form_instance, definition_identifier: 'test-custom-assessment', entity: p1, active: true, data_source: ds1 }
  let!(:inactive_rule) { create :hmis_form_instance, definition_identifier: 'test-custom-assessment', active: false, data_source: ds1 }

  before(:each) do
    hmis_login(user)
  end

  describe 'When requesting form rules' do
    let(:query) do
      <<~GRAPHQL
        query GetFormRules(
          $id: ID!
          $limit: Int = 25
          $offset: Int = 0
          $filters: FormRuleFilterOptions
          $sortOrder: FormRuleSortOption
        ) {
          formDefinition(id: $id) {
            id
            cacheKey
            formRules(
              limit: $limit
              offset: $offset
              filters: $filters
              sortOrder: $sortOrder
            ) {
              offset
              limit
              nodesCount
              nodes {
                #{scalar_fields(Types::Admin::FormRule)}
              }
            }
          }
        }
      GRAPHQL
    end

    def query_form_rules(id:, filters: nil, limit: 25)
      response, result = post_graphql(id: id, filters: filters, limit: limit) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'formDefinition', 'formRules', 'nodes')
    end

    it 'should return all custom form rules for a definition' do
      rules = query_form_rules(id: assessment.id)
      expect(rules.count).to eq(2)
    end

    it 'should return all seeded form rules for a hud service' do
      service_definition = Hmis::Form::Definition.in_data_source(ds1).with_role(:SERVICE).first
      rules = query_form_rules(id: service_definition.id)
      expect(rules.count).to be >= 10
    end

    it 'should filter form rules' do
      rules = query_form_rules(id: assessment.id, filters: { activeStatus: [:ACTIVE] })
      expect(rules.count).to eq(1)
      expect(rules.pluck('id')).not_to include(inactive_rule.id)
    end

    context 'when there are many form rules' do
      before do
        50.times do
          project = create(:hmis_hud_project, data_source: ds1, organization: o1)
          create(:hmis_form_instance, definition_identifier: 'test-custom-assessment', entity: project, data_source: ds1, active: true)
        end
        50.times do
          organization = create(:hmis_hud_organization, data_source: ds1)
          create(:hmis_form_instance, definition_identifier: 'test-custom-assessment', entity: organization, data_source: ds1, active: true)
        end
      end

      it 'avoids n+1' do
        expect do
          rules = query_form_rules(id: assessment.id, limit: 100)
          expect(rules.count).to eq(100)
        end.to make_database_queries(count: 5..15)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
