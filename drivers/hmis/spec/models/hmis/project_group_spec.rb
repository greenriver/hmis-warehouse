###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::ProjectGroup, type: :model do
  let!(:hmis_ds) { create(:hmis_data_source) }
  let!(:o1) { create(:hmis_hud_organization, data_source: hmis_ds) }
  let!(:o2) { create(:hmis_hud_organization, data_source: hmis_ds) }
  let!(:p1_o1) { create(:hmis_hud_project, data_source: hmis_ds, organization: o1, project_type: 1) }
  let!(:p2_o2) { create(:hmis_hud_project, data_source: hmis_ds, organization: o2, project_type: 2) }
  let!(:p3_o2) { create(:hmis_hud_project, data_source: hmis_ds, organization: o2, project_type: 3) }
  let!(:p4_o2) { create(:hmis_hud_project, data_source: hmis_ds, organization: o2, project_type: 4) }

  # project in another non-HMIS data source
  let!(:non_hmis_project) { create(:hmis_hud_project, data_source: create(:source_data_source)) }

  describe 'inclusion_criteria' do
    context 'when project_ids are specified' do
      let(:project_group) do
        create(:hmis_project_group, data_source: hmis_ds, inclusion_criteria: {
          project_ids: [p1_o1.id, p2_o2.id],
        }.to_json)
      end

      it 'includes projects specified by project_ids' do
        expect(project_group.effective_project_ids).to contain_exactly(p1_o1.id, p2_o2.id)
        expect(project_group.projects).to contain_exactly(p1_o1, p2_o2)
      end

      it 'does not include non-HMIS projects, even if specified' do
        project_group.parsed_inclusion_criteria.project_ids << non_hmis_project.id
        expect(project_group.effective_project_ids).not_to include(non_hmis_project.id)
      end
    end

    context 'when organization_ids are specified' do
      let(:project_group) do
        create(:hmis_project_group, data_source: hmis_ds, inclusion_criteria: {
          organization_ids: [o1.id],
        }.to_json)
      end

      it 'includes all projects belonging to the specified organizations' do
        expect(project_group.effective_project_ids).to contain_exactly(*o1.projects.pluck(:id))
      end
    end

    context 'when data_source_ids are specified' do
      let(:project_group) do
        create(:hmis_project_group, data_source: hmis_ds, inclusion_criteria: {
          data_source_ids: [hmis_ds.id],
        }.to_json)
      end

      it 'includes all projects from the specified data sources' do
        expect(project_group.effective_project_ids).to contain_exactly(*hmis_ds.projects.pluck(:id))
      end
    end

    context 'when project_type_numbers are specified' do
      let(:project_group) do
        create(:hmis_project_group, data_source: hmis_ds, inclusion_criteria: {
          project_type_numbers: [1],
        }.to_json)
      end

      it 'includes projects with the specified project types' do
        expect(project_group.effective_project_ids).to contain_exactly(p1_o1.id)
      end
    end

    context 'when multiple criteria are specified' do
      let(:project_group) do
        create(:hmis_project_group, data_source: hmis_ds, inclusion_criteria: {
          project_ids: [p2_o2.id],
          organization_ids: [o1.id],
          project_type_numbers: [3],
        }.to_json)
      end

      it 'includes all projects that satisfy criteria' do
        expected_projects = [p2_o2.id] + o1.projects.pluck(:id) + hmis_ds.projects.where(project_type: 3).pluck(:id)
        expect(project_group.effective_project_ids).to contain_exactly(*expected_projects)
      end
    end
  end

  describe 'exclusion_criteria' do
    context 'when project_ids are excluded' do
      let(:project_group) do
        create(:hmis_project_group,
               data_source: hmis_ds,
               including_entire_data_source: true,
               exclusion_criteria: {
                 project_ids: [p1_o1.id],
               }.to_json)
      end

      it 'excludes the specified projects by project_ids' do
        expect(project_group.effective_project_ids).to contain_exactly(*hmis_ds.projects.where.not(id: p1_o1.id).pluck(:id))
      end
    end

    context 'when project_type_numbers are excluded' do
      let(:project_group) do
        create(:hmis_project_group,
               data_source: hmis_ds,
               including_entire_data_source: true,
               exclusion_criteria: {
                 project_type_numbers: [2],
               }.to_json)
      end

      it 'excludes projects with the specified project types' do
        expect(project_group.effective_project_ids).to contain_exactly(*hmis_ds.projects.where.not(project_type: 2).pluck(:id))
      end
    end

    context 'when organization_ids are excluded' do
      let(:project_group) do
        create(:hmis_project_group,
               data_source: hmis_ds,
               including_entire_data_source: true,
               exclusion_criteria: {
                 organization_ids: [o2.id],
               }.to_json)
      end

      it 'excludes all projects belonging to the specified organizations' do
        expect(project_group.effective_project_ids).to contain_exactly(*(hmis_ds.projects.pluck(:id) - o2.projects.pluck(:id)))
      end
    end

    context 'when multiple exclusion criteria are specified' do
      let(:project_group) do
        create(:hmis_project_group,
               data_source: hmis_ds,
               including_entire_data_source: true,
               exclusion_criteria: {
                 project_ids: [p1_o1.id],
                 project_type_numbers: [2],
               }.to_json)
      end

      it 'excludes projects that match any of the exclusion criteria' do
        expected = hmis_ds.projects.where.not(project_type: 2).where.not(id: p1_o1.id).pluck(:id)
        expect(project_group.effective_project_ids).to contain_exactly(*expected)
        expect(project_group.projects.map(&:id)).to contain_exactly(*expected)
      end
    end
  end
end
