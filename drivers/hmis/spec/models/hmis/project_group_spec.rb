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

  describe 'access scopes' do
    let!(:non_admin_user) do
      hmis_user = create(:hmis_user, data_source: hmis_ds)
      create_access_control(hmis_user, o1, without_permission: [:can_administer_hmis])
      hmis_user
    end
    let!(:admin_user) do
      hmis_user = create(:hmis_user, data_source: hmis_ds)
      create_access_control(hmis_user, hmis_ds)
      hmis_user
    end
    let!(:project_group) { create(:hmis_project_group, data_source: hmis_ds) }

    it 'allows admin users to view project groups' do
      expect(Hmis::ProjectGroup.viewable_by(admin_user)).to include(project_group)
    end
    it 'allows admin users to edit project groups' do
      expect(Hmis::ProjectGroup.editable_by(admin_user)).to include(project_group)
    end
    it 'disallows non-admin users from viewing project groups' do
      expect(Hmis::ProjectGroup.viewable_by(non_admin_user)).to be_empty
    end
    it 'disallows non-admin users from editing project groups' do
      expect(Hmis::ProjectGroup.editable_by(non_admin_user)).to be_empty
    end
  end

  describe 'project evaluation' do
    context 'when both inclusion and exclusion criteria are specified' do
      let(:project_group) do
        create(:hmis_project_group,
               data_source: hmis_ds,
               inclusion_criteria: {
                 all_projects_in_data_source: true,
               }.to_json,
               exclusion_criteria: {
                 project_ids: [p1_o1.id],
                 project_type_numbers: [2],
               }.to_json)
      end

      it 'evaluates effective_project_ids correctly' do
        expected = hmis_ds.projects.where.not(project_type: 2).where.not(id: p1_o1.id).pluck(:id)

        # check effective_project_ids
        expect(project_group.effective_project_ids).to contain_exactly(*expected)

        # sanity check effective_project_ids for each criteria
        expect(project_group.parsed_inclusion_criteria.effective_project_ids).to contain_exactly(*hmis_ds.projects.map(&:id))
        expect(project_group.parsed_exclusion_criteria.effective_project_ids).to contain_exactly(p1_o1.id, p2_o2.id)
      end

      it 'maintains projects correctly' do
        expected = hmis_ds.projects.where.not(project_type: 2).where.not(id: p1_o1.id).pluck(:id)

        # check maintained projects
        expect(project_group.projects.map(&:id)).to contain_exactly(*expected)
      end
    end
  end
end
