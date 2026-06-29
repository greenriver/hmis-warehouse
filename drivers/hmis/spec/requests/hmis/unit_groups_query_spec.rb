# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Unit groups query', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_view_units, :can_administrate_coordinated_entry]) }
  let!(:beds_group) { create(:hmis_unit_group, project: p1, name: 'Beds') }
  let!(:vouchers_group) { create(:hmis_unit_group, project: p1, name: 'Vouchers') }

  let(:query) do
    <<~GRAPHQL
      query GetUnitGroups($filters: UnitGroupFilterOptions, $limit: Int) {
        unitGroups(filters: $filters, limit: $limit) {
          nodesCount
          nodes {
            id
            name
            project {
              id
              projectName
            }
            effectiveCeMatchRuleCount
            localCeMatchRuleCount
          }
        }
      }
    GRAPHQL
  end

  it 'returns all unit groups' do
    response, result = post_graphql { query }
    expect(response.status).to eq(200), result.inspect

    unit_groups = result.dig('data', 'unitGroups')
    expect(unit_groups['nodesCount']).to eq(2)
    expect(unit_groups['nodes']).to contain_exactly(
      include('id' => beds_group.id.to_s, 'name' => beds_group.name),
      include('id' => vouchers_group.id.to_s, 'name' => vouchers_group.name),
    )
  end

  it 'filters unit groups by search term' do
    response, result = post_graphql(filters: { searchTerm: 'bed' }) { query }
    expect(response.status).to eq(200), result.inspect

    unit_groups = result.dig('data', 'unitGroups')
    expect(unit_groups['nodesCount']).to eq(1)
    expect(unit_groups['nodes']).to contain_exactly(
      include(
        'id' => beds_group.id.to_s,
        'name' => beds_group.name,
      ),
    )
  end

  it 'filters unit groups by search term with project name' do
    matching_project = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1, ProjectName: 'Purple PSH')
    matching_group = create(:hmis_unit_group, project: matching_project, name: 'Maroon Beds')
    other_matching_group = create(:hmis_unit_group, project: matching_project, name: 'Indigo Vouchers')

    response, result = post_graphql(filters: { searchTerm: 'purple' }) { query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'unitGroups', 'nodes')).to contain_exactly(
      include('id' => matching_group.id.to_s, 'name' => matching_group.name),
      include('id' => other_matching_group.id.to_s, 'name' => other_matching_group.name),
    )
  end

  it 'filters unit groups by search term with unit group ID' do
    response, result = post_graphql(filters: { searchTerm: beds_group.id.to_s }) { query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'unitGroups', 'nodes')).to contain_exactly(
      include('id' => beds_group.id.to_s, 'name' => beds_group.name),
    )
  end

  it 'filters unit groups by CE waitlists enabled' do
    create(:hmis_project_ce_config, project: p1, supports_waitlist_referrals: true)
    other_project = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
    create(:hmis_unit_group, project: other_project, name: 'Not waitlist enabled')
    direct_referral_template = create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: ds1)
    create(:hmis_unit_group, project: p1, name: 'Direct referral only', workflow_template: nil, direct_referral_workflow_template: direct_referral_template)

    response, result = post_graphql(filters: { ceWaitlistsEnabled: true }) { query }
    expect(response.status).to eq(200), result.inspect

    unit_groups = result.dig('data', 'unitGroups')
    expect(unit_groups['nodesCount']).to eq(2)
    expect(unit_groups['nodes']).to contain_exactly(
      include(
        'id' => beds_group.id.to_s,
        'name' => beds_group.name,
      ),
      include(
        'id' => vouchers_group.id.to_s,
        'name' => vouchers_group.name,
      ),
    )
  end

  context 'with many unit groups in many projects' do
    before do
      10.times do |i|
        project = create(:hmis_hud_project, data_source: ds1, ProjectName: "Project #{i}")
        create(:hmis_unit_group, project: project, name: "Group #{i}")
      end
    end

    it 'avoids n+1s' do
      expect do
        response, result = post_graphql { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'unitGroups', 'nodes').size).to eq(12)
      end.to make_database_queries(count: 15..25)
    end
  end
end
