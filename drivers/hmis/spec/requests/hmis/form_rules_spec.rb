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

  let!(:assessment) { create :hmis_form_definition, identifier: 'test-custom-assessment', role: :CUSTOM_ASSESSMENT }
  let!(:assessment_rule) { create :hmis_form_instance, definition_identifier: 'test-custom-assessment', entity: p1, active: true }

  let!(:service) { create :hmis_form_definition, identifier: 'test-service', role: :SERVICE }
  let!(:service_rule) { create :hmis_form_instance, definition_identifier: 'test-service', entity: p1, active: true }

  before(:each) do
    hmis_login(user)
  end

  describe 'When requesting form rules' do
    let(:query) do
      <<~GRAPHQL
        query GetFormRules(
          $filters: FormRuleFilterOptions
        ) {
          formRules(
            filters: $filters
          ) {
            nodesCount
            nodes {
              id
              definitionRole
            }
          }
        }
      GRAPHQL
    end

    def query_form_rules(filters: nil)
      response, result = post_graphql(filters: filters) { query }
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
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
