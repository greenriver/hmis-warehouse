###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'updateCeMatchRule mutation', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    allow(Hmis::Ce::Match::RuleChangeImpactCalculator).to receive(:for_rule).and_return(no_impact)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_administrate_coordinated_entry]) }

  let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: ds1, name: 'Original', expression: 'current_age >= 18') }
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

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateCeMatchRule($id: ID!, $input: CeMatchRuleInput!, $confirmed: Boolean) {
        updateCeMatchRule(id: $id, input: $input, confirmed: $confirmed) {
          rule {
            id
            name
            expression
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'updates basic attributes without running impact preview when rule logic is unchanged' do
    response, result = post_graphql(id: rule.id, input: { name: 'Renamed rule' }) { mutation }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'updateCeMatchRule', 'rule')).to include(
      'id' => rule.id.to_s,
      'name' => 'Renamed rule',
    )
    expect(Hmis::Ce::Match::RuleChangeImpactCalculator).not_to have_received(:for_rule)
  end

  it 'updates from structured expression input' do
    input = {
      structuredExpression: {
        operator: 'OR',
        clauses: [
          { field: 'current_age', comparator: 'LT', value: 18 },
        ],
      },
    }

    response, result = post_graphql(id: rule.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateCeMatchRule', 'rule', 'expression')).to eq('current_age < 18')
  end

  it 'returns impact warnings without saving until confirmed when expression changes' do
    allow(Hmis::Ce::Match::RuleChangeImpactCalculator).to receive(:for_rule).and_return(warning_impact)

    expect do
      response, result = post_graphql(id: rule.id, input: { expression: 'current_age >= 65' }) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'updateCeMatchRule', 'errors').first).to include('severity' => 'warning')
    end.not_to(change { rule.reload.expression })

    response, result = post_graphql(id: rule.id, input: { expression: 'current_age >= 65' }, confirmed: true) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateCeMatchRule', 'rule', 'expression')).to eq('current_age >= 65')
  end

  it 'rejects attempts to change immutable owner and type fields' do
    input = {
      ownerId: other_data_source.id,
      ownerType: 'PROJECT',
      ruleType: 'PRIORITY_SCHEME',
    }

    response, result = post_graphql(id: rule.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'updateCeMatchRule', 'rule')).to be_nil
    expect(result.dig('data', 'updateCeMatchRule', 'errors')).to contain_exactly(
      a_hash_including('attribute' => 'ownerId', 'message' => 'cannot be changed once set'),
      a_hash_including('attribute' => 'ownerType', 'message' => 'cannot be changed once set'),
      a_hash_including('attribute' => 'ruleType', 'message' => 'cannot be changed once set'),
    )
    expect(rule.reload).to have_attributes(
      owner_id: ds1.id,
      owner_type: 'GrdaWarehouse::DataSource',
      rule_type: 'eligibility_requirement',
    )
  end

  context 'when the user lacks can_administrate_coordinated_entry' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_coordinated_entry) }

    it 'denies access' do
      expect_access_denied post_graphql(id: rule.id, input: { name: 'Should not update' }) { mutation }
    end
  end

  context 'when the rule is in another data source' do
    let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: other_data_source, name: 'Other DS') }

    it 'denies access' do
      expect_access_denied post_graphql(id: rule.id, input: { name: 'Should not update' }) { mutation }
    end
  end
end
