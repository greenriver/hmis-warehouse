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
  let!(:project) { create(:hmis_hud_project, data_source: ds1) }
  let!(:global_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: ds1,
      name: 'Must be 18 or older',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'current_age >= 18',
      applicability_config: {},
    )
  end
  let!(:global_priority_scheme) do
    Hmis::Ce::Match::Rule.create!(
      owner: ds1,
      name: 'Prioritize older clients',
      rule_type: Hmis::Ce::Match::Rule::PRIORITY_SCHEME,
      expression: 'current_age',
      priority_rank: 1,
      applicability_config: {},
    )
  end
  let!(:project_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: project,
      name: 'Project rule',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'current_age >= 24',
      applicability_config: {},
    )
  end
  let!(:custom_assessment_form) do
    create(
      :hmis_form_definition,
      identifier: 'score_assessment',
      title: 'Score Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :published,
      data_source: ds1,
    )
  end
  let!(:score_cded) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'score',
      label: 'Score',
      field_type: :integer,
      form_definition: custom_assessment_form,
      data_source: ds1,
    )
  end
  let!(:custom_data_element_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: project,
      name: 'Assessment score required',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: '`cde.custom_assessment.score` >= 10',
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
              fieldSource
              formDefinitionIdentifier
              comparator
              value
            }
          }
        }
      }
    GRAPHQL
  end

  it 'returns global rules for the current data source' do
    response, result = post_graphql(filters: { global: true }) { rules_query }
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

  it 'returns structured expression details for a client field rule' do
    response, result = post_graphql(id: global_rule.id) { rule_query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'ceMatchRule', 'structuredExpression')).to include(
      'operator' => 'AND',
      'clauses' => [
        include(
          'field' => 'current_age',
          'fieldSource' => 'CLIENT',
          'formDefinitionIdentifier' => nil,
          'comparator' => 'GTE',
          'value' => 18,
        ),
      ],
    )
  end

  it 'returns structured expression details for a custom data element rule' do
    response, result = post_graphql(id: custom_data_element_rule.id) { rule_query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'ceMatchRule', 'structuredExpression', 'clauses')).to contain_exactly(
      include(
        'field' => 'cde.custom_assessment.score',
        'fieldSource' => 'CUSTOM_DATA_ELEMENT',
        'formDefinitionIdentifier' => 'score_assessment',
        'comparator' => 'GTE',
        'value' => 10,
      ),
    )
  end

  it 'denies access without can_administrate_coordinated_entry' do
    remove_permissions(access_control, :can_administrate_coordinated_entry)

    expect_access_denied(post_graphql(filters: { global: true }) { rules_query })
    expect_access_denied(post_graphql(id: global_rule.id) { rule_query })
  end
end
