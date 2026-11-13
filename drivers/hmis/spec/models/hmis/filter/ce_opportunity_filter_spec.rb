###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

RSpec.describe Hmis::Filter::CeOpportunityFilter, type: :model do
  let(:data_source) { create(:hmis_primary_data_source) }

  def apply_filter(scope, project_group_id:)
    input = OpenStruct.new(project_group_id: project_group_id)
    described_class.new(input).filter_scope(scope)
  end

  describe '#filter_scope with project_group_id' do
    let!(:project_in_group) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project_outside_group) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project_group) do
      create(:hmis_project_group, data_source: data_source, with_projects: [project_in_group])
    end

    let!(:unit_group_in_group) { create(:hmis_unit_group, project: project_in_group) }
    let!(:unit_group_outside_group) { create(:hmis_unit_group, project: project_outside_group) }
    let!(:unit_in_group) { create(:hmis_unit, project: project_in_group, unit_group: unit_group_in_group) }
    let!(:unit_outside_group) { create(:hmis_unit, project: project_outside_group, unit_group: unit_group_outside_group) }
    let!(:opportunity_in_group) { create(:hmis_ce_opportunity, unit: unit_in_group) }
    let!(:opportunity_outside_group) { create(:hmis_ce_opportunity, unit: unit_outside_group) }
    let(:base_scope) { Hmis::Ce::Opportunity.where(id: [opportunity_in_group.id, opportunity_outside_group.id]) }

    it 'filters opportunities to projects in the project group' do
      result = apply_filter(base_scope, project_group_id: project_group.id)
      expect(result).to contain_exactly(opportunity_in_group)
    end

    it 'returns no rows for an unknown project group' do
      expect(apply_filter(base_scope, project_group_id: -1)).to be_empty
    end
  end
end
