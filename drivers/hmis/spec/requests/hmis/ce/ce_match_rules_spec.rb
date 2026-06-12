# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'CE Match Rules queries', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_administrate_coordinated_entry]) }
  let(:other_data_source) { create(:hmis_data_source) }
  let!(:global_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: ds1,
      name: 'Must be 18 or older',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'current_age >= 18',
      applicability_config: {},
    )
  end
  let!(:other_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: other_data_source,
      name: 'Other data source rule',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'current_age >= 21',
      applicability_config: {},
    )
  end

  let(:rules_query) do
    <<~GRAPHQL
      query GetCeMatchRules($filters: CeMatchRuleFilterOptions) {
        ceMatchRules(filters: $filters) {
          nodesCount
          nodes {
            id
            name
            ownerId
            ownerName
            ownerType
            ruleType
            priorityRank
            expression
          }
        }
      }
    GRAPHQL
  end

  let(:rule_query) do
    <<~GRAPHQL
      query GetCeMatchRule($id: ID!) {
        ceMatchRule(id: $id) {
          id
          name
          structuredExpression {
            operator
            clauses {
              field
              comparator
              value
            }
          }
        }
      }
    GRAPHQL
  end

  it 'returns global rules for the current data source' do
    response, result = post_graphql(filters: { ownerType: 'DATA_SOURCE' }) { rules_query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'ceMatchRules', 'nodesCount')).to eq(1)
    expect(result.dig('data', 'ceMatchRules', 'nodes')).to contain_exactly(
      include(
        'id' => global_rule.id.to_s,
        'name' => 'Must be 18 or older',
        'ownerId' => ds1.id.to_s,
        'ownerName' => 'Global',
        'ownerType' => 'DATA_SOURCE',
        'ruleType' => 'ELIGIBILITY_REQUIREMENT',
        'priorityRank' => nil,
        'expression' => 'current_age >= 18',
      ),
    )
  end

  it 'returns structured expression details for a rule' do
    response, result = post_graphql(id: global_rule.id) { rule_query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'ceMatchRule', 'structuredExpression')).to include(
      'operator' => 'AND',
      'clauses' => [
        include('field' => 'current_age', 'comparator' => 'GTE', 'value' => 18),
      ],
    )
  end

  it 'denies access without can_administrate_coordinated_entry' do
    remove_permissions(access_control, :can_administrate_coordinated_entry)

    expect_access_denied(post_graphql(filters: { ownerType: 'DATA_SOURCE' }) { rules_query })
    expect_access_denied(post_graphql(id: global_rule.id) { rule_query })
  end
end
