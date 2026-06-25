# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'Project CE Match Rules queries', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_administrate_coordinated_entry]) }
  let!(:global_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: ds1,
      name: 'Must be 18 or older',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'current_age >= 18',
      applicability_config: {},
    )
  end
  let!(:organization_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: o1,
      name: 'Must be a veteran',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'veteran_status = 1',
      applicability_config: {},
    )
  end
  let!(:project_rule) do
    Hmis::Ce::Match::Rule.create!(
      owner: p1,
      name: 'Must be living with a disability',
      rule_type: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT,
      expression: 'EXCLUDES(open_enrollment_project_types, PROJECT_TYPE("PH_PSH"))',
      applicability_config: {},
    )
  end

  let(:project_rules_query) do
    <<~GRAPHQL
      query GetProjectCeMatchRules($id: ID!) {
        project(id: $id) {
          id
          effectiveCeMatchRuleCount
          localCeMatchRuleCount
          effectiveCeMatchRuleGroups {
            ownerId
            ownerName
            ownerType
            local
            rules {
              nodesCount
              nodes {
                id
                name
                ownerType
              }
            }
          }
        }
      }
    GRAPHQL
  end

  it 'returns effective CE match rule groups for a project' do
    response, result = post_graphql(id: p1.id) { project_rules_query }
    expect(response.status).to eq(200), result.inspect

    project = result.dig('data', 'project')
    expect(project).to include(
      'effectiveCeMatchRuleCount' => 3,
      'localCeMatchRuleCount' => 1,
    )
    expect(project['effectiveCeMatchRuleGroups']).to contain_exactly(
      include(
        'ownerName' => 'Global',
        'ownerType' => 'DATA_SOURCE',
        'local' => false,
        'rules' => include(
          'nodesCount' => 1,
          'nodes' => [include('id' => global_rule.id.to_s, 'name' => global_rule.name)],
        ),
      ),
      include(
        'ownerName' => o1.name,
        'ownerType' => 'ORGANIZATION',
        'local' => false,
        'rules' => include(
          'nodesCount' => 1,
          'nodes' => [include('id' => organization_rule.id.to_s, 'name' => organization_rule.name)],
        ),
      ),
      include(
        'ownerName' => p1.name,
        'ownerType' => 'PROJECT',
        'local' => true,
        'rules' => include(
          'nodesCount' => 1,
          'nodes' => [include('id' => project_rule.id.to_s, 'name' => project_rule.name)],
        ),
      ),
    )
  end

  it 'denies access without can_administrate_coordinated_entry' do
    remove_permissions(access_control, :can_administrate_coordinated_entry)

    expect_access_denied post_graphql(id: p1.id) { project_rules_query }
  end
end
