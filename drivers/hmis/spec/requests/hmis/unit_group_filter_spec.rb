# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Unit Group filters', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_view_units]) }
  let!(:beds_group) { create(:hmis_unit_group, project: p1, name: 'Beds') }
  let!(:vouchers_group) { create(:hmis_unit_group, project: p1, name: 'Vouchers') }

  let(:query) do
    <<~GRAPHQL
      query GetUnitGroups($filters: UnitGroupFilterOptions) {
        unitGroups(filters: $filters) {
          nodesCount
          nodes {
            id
            name
          }
        }
      }
    GRAPHQL
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

  it 'filters unit groups by CE waitlists enabled' do
    create(:hmis_project_ce_config, project: p1, supports_waitlist_referrals: true)
    other_project = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
    create(:hmis_unit_group, project: other_project, name: 'Not waitlist enabled')

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

  it 'filters unit groups by project name' do
    matching_project = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1, ProjectName: 'Purple PSH')
    matching_group = create(:hmis_unit_group, project: matching_project, name: 'Scattered Sites')
    other_matching_group = create(:hmis_unit_group, project: matching_project, name: 'Congregate Sites')

    response, result = post_graphql(filters: { searchTerm: 'purple' }) { query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'unitGroups', 'nodes')).to contain_exactly(
      include('id' => matching_group.id.to_s, 'name' => matching_group.name),
      include('id' => other_matching_group.id.to_s, 'name' => other_matching_group.name),
    )
  end

  it 'filters unit groups by unit group ID' do
    response, result = post_graphql(filters: { searchTerm: beds_group.id.to_s }) { query }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'unitGroups', 'nodes')).to contain_exactly(
      include('id' => beds_group.id.to_s, 'name' => beds_group.name),
    )
  end
end
