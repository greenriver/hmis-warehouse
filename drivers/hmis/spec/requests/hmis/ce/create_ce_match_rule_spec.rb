###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'createCeMatchRule mutation', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    allow(Hmis::Ce::Match::RuleChangeImpactCalculator).to receive(:for_rule).and_return(no_impact)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_administrate_coordinated_entry]) }
  let(:unit_group) { create(:hmis_unit_group, project: p1, name: 'Housing Match Group') }
  let(:other_data_source) { create(:hmis_data_source) }

  let(:no_impact) { Hmis::Ce::Match::RuleChangeImpactCalculator::Result.new(affected_unit_groups: []) }

  let(:warning_impact) do
    Hmis::Ce::Match::RuleChangeImpactCalculator::Result.new(
      affected_unit_groups: [
        Hmis::Ce::Match::RuleChangeImpactCalculator::UnitGroupImpact.new(
          unit_group: unit_group,
          current_candidate_count: 4,
          removed_candidate_count: 1,
        ),
      ],
    )
  end

  let(:base_input) do
    {
      name: 'Must be 18 or older',
      ownerId: ds1.id,
      ownerType: 'DATA_SOURCE',
      ruleType: 'eligibility_requirement',
      expression: 'current_age >= 18',
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateCeMatchRule($input: CeMatchRuleInput!, $confirmed: Boolean) {
        createCeMatchRule(input: $input, confirmed: $confirmed) {
          rule {
            id
            name
            expression
            structuredExpression {
              operator
              clauses {
                field
                comparator
                value
              }
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'creates an eligibility requirement from free-text expression input' do
    expect do
      response, result = post_graphql(input: base_input) { mutation }
      expect(response.status).to eq(200), result.inspect

      rule = result.dig('data', 'createCeMatchRule', 'rule')
      expect(rule).to include(
        'name' => 'Must be 18 or older',
        'expression' => 'current_age >= 18',
      )
    end.to change(Hmis::Ce::Match::Rule, :count).by(1)
  end

  it 'creates a priority scheme' do
    input = base_input.merge(
      ruleType: 'priority_scheme',
      expression: 'current_age',
      priorityRank: 1,
    )

    expect do
      response, result = post_graphql(input: input) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'createCeMatchRule', 'rule', 'expression')).to eq('current_age')
    end.to change(Hmis::Ce::Match::Rule, :count).by(1)

    expect(Hmis::Ce::Match::RuleChangeImpactCalculator).not_to have_received(:for_rule)
  end

  it 'creates a rule from structured expression input' do
    input = base_input.except(:expression).merge(
      structuredExpression: {
        operator: 'AND',
        clauses: [
          { field: 'current_age', comparator: 'GTE', value: 18 },
        ],
      },
    )

    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'createCeMatchRule', 'rule', 'expression')).to eq('current_age >= 18')
  end

  it 'coerces enum-backed structured expression values' do
    input = base_input.except(:expression).merge(
      structuredExpression: {
        operator: 'AND',
        clauses: [
          { field: 'veteran_status', comparator: 'EQ', value: 'YES' },
        ],
      },
    )

    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'createCeMatchRule', 'rule', 'expression')).to eq('veteran_status = 1')
  end

  it 'returns validation errors without saving' do
    # Validation is tested more thoroughly in the spec for Hmis::Ce::Match::Expression::Validator
    expect do
      response, result = post_graphql(input: base_input.merge(expression: 'current_age >')) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'createCeMatchRule', 'errors')
      expect(errors.first).to include('attribute' => 'expression', 'severity' => 'error')
    end.not_to change(Hmis::Ce::Match::Rule, :count)
  end

  it 'returns impact warnings without saving until confirmed' do
    allow(Hmis::Ce::Match::RuleChangeImpactCalculator).to receive(:for_rule).and_return(warning_impact)

    expect do
      response, result = post_graphql(input: base_input) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'createCeMatchRule', 'errors')
      expect(errors.first).to include('severity' => 'warning')
      expect(errors.first.dig('data', 'affectedUnitGroups').first).to include(
        'id' => unit_group.id.to_s,
        'unitGroupName' => unit_group.name,
        'projectId' => p1.id.to_s,
        'projectName' => p1.name,
        'currentCandidateCount' => 4,
        'removedCandidateCount' => 1,
      )
    end.not_to change(Hmis::Ce::Match::Rule, :count)

    expect do
      response, result = post_graphql(input: base_input, confirmed: true) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'createCeMatchRule', 'rule')).to be_present
    end.to change(Hmis::Ce::Match::Rule, :count).by(1)
  end

  it 'denies access without can_administrate_coordinated_entry' do
    remove_permissions(access_control, :can_administrate_coordinated_entry)

    expect_access_denied post_graphql(input: base_input) { mutation }
  end

  it 'denies access when the owner is in another data source' do
    expect_access_denied post_graphql(input: base_input.merge(ownerId: other_data_source.id)) { mutation }
  end
end
