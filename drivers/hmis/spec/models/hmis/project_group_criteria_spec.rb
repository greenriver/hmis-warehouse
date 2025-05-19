###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::ProjectGroupCriteria, type: :model do
  let!(:hmis_ds) { create(:hmis_data_source) }
  let!(:o1) { create(:hmis_hud_organization, data_source: hmis_ds) }
  let!(:o2) { create(:hmis_hud_organization, data_source: hmis_ds) }
  let!(:p1_o1) { create(:hmis_hud_project, data_source: hmis_ds, organization: o1, project_type: 1) }
  let!(:p2_o2) { create(:hmis_hud_project, data_source: hmis_ds, organization: o2, project_type: 2) }
  let!(:p3_o2) { create(:hmis_hud_project, data_source: hmis_ds, organization: o2, project_type: 3) }
  let!(:p4_o2) { create(:hmis_hud_project, data_source: hmis_ds, organization: o2, project_type: 4) }

  # project in another non-HMIS data source
  let!(:non_hmis_project) { create(:hmis_hud_project, data_source: create(:source_data_source)) }

  describe '#effective_project_ids' do
    context 'when project_ids are specified' do
      let(:criteria) do
        Hmis::ProjectGroupCriteria.new(
          { project_ids: [p1_o1.id, p2_o2.id] },
          data_source_id: hmis_ds.id,
        )
      end

      it 'includes projects specified by project_ids' do
        expect(criteria.effective_project_ids).to contain_exactly(p1_o1.id, p2_o2.id)
      end

      it 'does not include non-HMIS projects, even if specified' do
        criteria.project_ids << non_hmis_project.id
        expect(criteria.effective_project_ids).not_to include(non_hmis_project.id)
      end
    end

    context 'when organization_ids are specified' do
      let(:criteria) do
        Hmis::ProjectGroupCriteria.new(
          { organization_ids: [o1.id] },
          data_source_id: hmis_ds.id,
        )
      end

      it 'includes all projects belonging to the specified organizations' do
        expect(criteria.effective_project_ids).to contain_exactly(*o1.projects.pluck(:id))
        expect(criteria.effective_project_ids.count).to eq(1)
      end
    end

    context 'when all_projects_in_data_source is true' do
      let(:criteria) do
        Hmis::ProjectGroupCriteria.new(
          { all_projects_in_data_source: true },
          data_source_id: hmis_ds.id,
        )
      end

      it 'includes all projects from the specified data sources' do
        expect(criteria.effective_project_ids).to contain_exactly(*hmis_ds.projects.pluck(:id))
        expect(criteria.effective_project_ids.count).to eq(4)
      end
    end

    context 'when project_type_numbers are specified' do
      let(:criteria) do
        Hmis::ProjectGroupCriteria.new(
          { project_type_numbers: [1] },
          data_source_id: hmis_ds.id,
        )
      end

      it 'includes projects with the specified project types' do
        expect(criteria.effective_project_ids).to contain_exactly(p1_o1.id)
      end
    end

    context 'when multiple criteria are specified' do
      let(:criteria) do
        Hmis::ProjectGroupCriteria.new(
          {
            project_ids: [p2_o2.id],
            organization_ids: [o1.id],
            project_type_numbers: [3],
          },
          data_source_id: hmis_ds.id,
        )
      end

      it 'includes all projects that satisfy criteria' do
        expect(criteria.effective_project_ids.count).to eq(3)
        expect(criteria.effective_project_ids).to include(p2_o2.id) # from project_ids
        expect(criteria.effective_project_ids).to include(p1_o1.id) # from organization_ids
        expect(criteria.effective_project_ids).to include(p3_o2.id) # from project_type_numbers
      end
    end
  end
end
