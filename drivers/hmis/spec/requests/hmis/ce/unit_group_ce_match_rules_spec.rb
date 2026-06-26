# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'Unit Group CE Match Rules queries', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_view_units, :can_administrate_coordinated_entry]) }
  let!(:unit_group) { create(:hmis_unit_group, project: p1, name: 'Beds') }
  let!(:global_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: ds1,
      name: 'Must be 18 or older',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'current_age >= 18',
      applicability_config: {},
    )
  end
  let!(:project_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: p1,
      name: 'Must not be enrolled in PSH',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'EXCLUDES(open_enrollment_project_types, PROJECT_TYPE("PH_PSH"))',
      applicability_config: {},
    )
  end
  let!(:unit_group_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: unit_group,
      name: 'Must be a veteran',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'veteran_status = 1',
      applicability_config: {},
    )
  end

  let(:unit_group_rules_query) do
    <<~GRAPHQL
      query GetUnitGroupCeMatchRules($id: ID!) {
        unitGroup(id: $id) {
          id
          effectiveCeMatchRuleCount
          localCeMatchRuleCount
          project {
            id
            projectName
            organization {
              id
              organizationName
            }
          }
          effectiveCeMatchRuleGroups {
            ownerId
            ownerName
            ownerType
            local
            rules {
              id
              name
            }
          }
        }
      }
    GRAPHQL
  end

  let(:unit_group_selector_query) do
    <<~GRAPHQL
      query GetUnitGroups($filters: UnitGroupFilterOptions) {
        unitGroups(filters: $filters) {
          nodesCount
          nodes {
            id
            name
            effectiveCeMatchRuleCount
            localCeMatchRuleCount
          }
        }
      }
    GRAPHQL
  end

  it 'returns effective CE match rule groups for a unit group' do
    response, result = post_graphql(id: unit_group.id) { unit_group_rules_query }
    expect(response.status).to eq(200), result.inspect

    result_unit_group = result.dig('data', 'unitGroup')
    expect(result_unit_group).to include(
      'effectiveCeMatchRuleCount' => 3,
      'localCeMatchRuleCount' => 1,
    )
    expect(result_unit_group['effectiveCeMatchRuleGroups']).to contain_exactly(
      include(
        'ownerName' => 'Global',
        'ownerType' => 'DATA_SOURCE',
        'local' => false,
        'rules' => include(
          include('id' => global_rule.id.to_s, 'name' => global_rule.name),
        ),
      ),
      include(
        'ownerName' => o1.name,
        'ownerType' => 'ORGANIZATION',
        'local' => false,
        'rules' => [], # returns an empty group for ancestor with no rules defined at that level
      ),
      include(
        'ownerName' => p1.name,
        'ownerType' => 'PROJECT',
        'local' => false,
        'rules' => include(
          include('id' => project_rule.id.to_s, 'name' => project_rule.name),
        ),
      ),
      include(
        'ownerName' => unit_group.name,
        'ownerType' => 'UNIT_GROUP',
        'local' => true,
        'rules' => include(
          include('id' => unit_group_rule.id.to_s, 'name' => unit_group_rule.name),
        ),
      ),
    )
  end

  # todo @martha - move to a separate file to test general filtering
  it 'returns filtered unit groups with CE match rule counts' do
    create(:hmis_project_ce_config, project: p1, supports_waitlist_referrals: true)
    other_project = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
    create(:hmis_unit_group, project: other_project, name: 'Not waitlist enabled')

    response, result = post_graphql(filters: { searchTerm: 'bed', ceWaitlistsEnabled: true }) { unit_group_selector_query }
    expect(response.status).to eq(200), result.inspect

    unit_groups = result.dig('data', 'unitGroups')
    expect(unit_groups['nodesCount']).to eq(1)
    expect(unit_groups['nodes']).to contain_exactly(
      include(
        'id' => unit_group.id.to_s,
        'name' => unit_group.name,
        'effectiveCeMatchRuleCount' => 3,
        'localCeMatchRuleCount' => 1,
      ),
    )
  end

  it 'denies CE rule fields without can_administrate_coordinated_entry' do
    remove_permissions(access_control, :can_administrate_coordinated_entry)

    expect_access_denied post_graphql(id: unit_group.id) { unit_group_rules_query }
  end
end
