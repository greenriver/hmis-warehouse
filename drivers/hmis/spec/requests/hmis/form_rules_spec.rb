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

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let!(:assessment) { create :hmis_form_definition, identifier: 'test-custom-assessment', role: :CUSTOM_ASSESSMENT }
  let!(:assessment_rule) { create :hmis_form_instance, definition_identifier: 'test-custom-assessment', entity: p1, active: true }

  let!(:service) { create :hmis_form_definition, identifier: 'test-service', role: :SERVICE }
  let!(:service_rule) { create :hmis_form_instance, definition_identifier: 'test-service', entity: p1, active: true, custom_service_category: create(:hmis_custom_service_category, data_source: ds1) }

  before(:each) do
    hmis_login(user)
  end

  describe 'When requesting form rules' do
    let(:query) do
      <<~GRAPHQL
        query GetFormRules(
          $filters: FormRuleFilterOptions
          $limit: Int
        ) {
          formRules(
            filters: $filters
            limit: $limit
          ) {
            nodesCount
            nodes {
              id
              definitionId
              definitionRole
              definitionTitle
              projectId
              projectName
              organizationId
              organization {
                id
                organizationName
              }
            }
          }
        }
      GRAPHQL
    end

    def query_form_rules(filters: nil, limit: 25)
      response, result = post_graphql(filters: filters, limit: limit) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'formRules', 'nodes')
    end

    it 'should return all form rules when the user has full access' do
      rules = query_form_rules
      expect(rules.count).to be >= 10
    end

    it 'should return filtered form rules' do
      rules = query_form_rules(filters: { form_type: [:INTAKE] })
      expect(rules.count).to eq(1)
      expect(rules.dig(0, 'definitionRole')).to eq('INTAKE')
    end

    it 'should return only rules with appropriate roles when the user is not a super admin' do
      remove_permissions(access_control, :can_administrate_config)
      rules = query_form_rules
      expect(rules.count).to eq(2)
      expect(rules.pluck('definitionRole')).to contain_exactly('CUSTOM_ASSESSMENT', 'SERVICE')

      rules = query_form_rules(filters: { form_type: [:INTAKE] })
      expect(rules.count).to eq(0)
    end

    context 'when there are many form rules' do
      before do
        Hmis::Form::Instance.destroy_all # clear existing rules
        50.times do
          project = create(:hmis_hud_project, data_source: ds1, organization: o1)
          create(:hmis_form_instance, definition_identifier: 'test-custom-assessment', entity: project, active: true)
        end
        50.times do
          organization = create(:hmis_hud_organization, data_source: ds1)
          create(:hmis_form_instance, definition_identifier: 'test-custom-assessment', entity: organization, active: true)
        end
      end

      it 'avoids n+1' do
        expect do
          rules = query_form_rules(limit: 100)
          expect(rules.count).to eq(100)
        end.to make_database_queries(count: 5..10)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
