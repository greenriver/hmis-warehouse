###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

RSpec.describe Hmis::Filter::CeClientFilter, type: :model do
  let(:data_source) { create(:hmis_primary_data_source) }

  def apply_filters(scope, project_group_id:)
    input = OpenStruct.new(project_group_id: project_group_id, search_term: nil, project_type: nil, dynamic_filters: [])
    described_class.new(input).filter_scope(scope)
  end

  describe '#filter_scope with project_group_id' do
    let!(:project_in_group) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project_outside_group) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project_group) do
      create(:hmis_project_group, data_source: data_source, with_projects: [project_in_group])
    end

    let!(:candidate_pool_in_group) { create(:hmis_ce_match_candidate_pool) }
    let!(:candidate_pool_outside_group) { create(:hmis_ce_match_candidate_pool) }
    let!(:unit_group_in_group) { create(:hmis_unit_group, project: project_in_group, candidate_pool: candidate_pool_in_group) }
    let!(:unit_group_outside_group) { create(:hmis_unit_group, project: project_outside_group, candidate_pool: candidate_pool_outside_group) }

    let!(:client_in_group) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
    let!(:client_outside_group) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
    let!(:proxy_in_group) { create(:hmis_ce_client_proxy, client: client_in_group.destination_client) }
    let!(:proxy_outside_group) { create(:hmis_ce_client_proxy, client: client_outside_group.destination_client) }

    let(:base_scope) { Hmis::Ce::ClientProxy.where(id: [proxy_in_group.id, proxy_outside_group.id]) }

    before do
      # unit_group_in_group
      # unit_group_outside_group
      create(:hmis_ce_match_candidate, candidate_pool: candidate_pool_in_group, client_proxy: proxy_in_group)
      create(:hmis_ce_match_candidate, candidate_pool: candidate_pool_outside_group, client_proxy: proxy_outside_group)
    end

    it 'filters client proxies to clients eligible for projects in the project group' do
      result = apply_filters(base_scope, project_group_id: project_group.id)
      expect(result).to contain_exactly(proxy_in_group)
    end

    it 'returns no rows for an unknown project group' do
      expect(apply_filters(base_scope, project_group_id: -1)).to be_empty
    end
  end
end
