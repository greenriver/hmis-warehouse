###
# Copyright Green River Data Group, Inc.
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

    context 'when coc_codes are specified' do
      let!(:p1_coc) { create(:hmis_hud_project_coc, data_source: hmis_ds, project: p1_o1, CoCCode: 'MA-500') }
      let!(:p2_coc) { create(:hmis_hud_project_coc, data_source: hmis_ds, project: p2_o2, CoCCode: 'MA-501') }

      let(:criteria) do
        Hmis::ProjectGroupCriteria.new(
          { coc_codes: ['MA-500'] },
          data_source_id: hmis_ds.id,
        )
      end

      it 'includes projects with a matching ProjectCoC record' do
        expect(criteria.effective_project_ids).to contain_exactly(p1_o1.id)
      end

      it 'does not include projects when the matching ProjectCoC record is soft-deleted' do
        p1_coc.destroy

        expect(criteria.effective_project_ids).to be_empty
      end

      it 'does not include projects from another data source, even if specified' do
        other_ds = create(:hmis_data_source)
        other_project = create(:hmis_hud_project, data_source: other_ds)
        create(:hmis_hud_project_coc, data_source: other_ds, project: other_project, CoCCode: 'MA-500')

        expect(criteria.effective_project_ids).to contain_exactly(p1_o1.id)
      end
    end

    context 'when a project serves multiple CoCs' do
      let!(:multi_coc_project) { create(:hmis_hud_project, data_source: hmis_ds, organization: o1) }

      before do
        create(:hmis_hud_project_coc, data_source: hmis_ds, project: multi_coc_project, CoCCode: 'MA-500')
        create(:hmis_hud_project_coc, data_source: hmis_ds, project: multi_coc_project, CoCCode: 'MA-501')
      end

      it 'includes the project when criteria include MA-500' do
        criteria = described_class.new({ coc_codes: ['MA-500'] }, data_source_id: hmis_ds.id)

        expect(criteria.effective_project_ids).to include(multi_coc_project.id)
      end

      it 'includes the project when criteria include MA-500 and MA-501' do
        criteria = described_class.new({ coc_codes: ['MA-500', 'MA-501'] }, data_source_id: hmis_ds.id)

        expect(criteria.effective_project_ids).to include(multi_coc_project.id)
      end

      it 'does not include the project when inclusion includes MA-500 and exclusion includes MA-501' do
        inclusion = described_class.new({ coc_codes: ['MA-500'] }, data_source_id: hmis_ds.id)
        exclusion = described_class.new({ coc_codes: ['MA-501'] }, data_source_id: hmis_ds.id)

        expect(inclusion.effective_project_ids - exclusion.effective_project_ids).not_to include(multi_coc_project.id)
      end
    end

    context 'when closed_projects is true' do
      let!(:closed_project) do
        create(:hmis_hud_project, data_source: hmis_ds, organization: o1, OperatingEndDate: 1.day.ago)
      end
      let!(:future_project) do
        create(:hmis_hud_project, data_source: hmis_ds, organization: o1, OperatingStartDate: 1.day.from_now)
      end
      let(:criteria) do
        described_class.new(
          { closed_projects: true },
          data_source_id: hmis_ds.id,
        )
      end

      it 'includes projects that are not currently open' do
        expect(criteria.effective_project_ids).to include(closed_project.id, future_project.id)
        expect(criteria.effective_project_ids).not_to include(p1_o1.id, p2_o2.id)
      end
    end
  end
end
