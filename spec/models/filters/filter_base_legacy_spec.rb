###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Filters::FilterBase, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:es_project) { create :grda_warehouse_hud_project, ProjectType: 1, OrganizationID: organization.OrganizationID }
  let!(:psh_project) { create :grda_warehouse_hud_project, ProjectType: 3, OrganizationID: organization.OrganizationID }
  let!(:user) { create :user }

  before :each do
    user.add_viewable(data_source)
  end

  describe 'FilterBase' do
    it 'defaults to nothing if nothing is specified' do
      filter_params = {
      }
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'only includes projects if they are included somehow, even if ph is specified' do
      filter_params = {
        project_type_codes: [:ph],
      }
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'does not include ES if projects are specified, but includes the specified project' do
      filter_params = {
        project_ids: [psh_project.id],
        project_type_codes: [],
      }
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).to include psh_project.id
    end

    it 'does not include any projects if project type codes is empty' do
      filter_params = {
        project_type_codes: [],
      }
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).not_to include psh_project.id
    end
  end

  describe 'HudFilterBase' do
    it 'HUD filter does not include any projects if nothing is specified' do
      filter_params = {
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'includes the PSH if type ph is specified' do
      filter_params = {
        project_type_codes: [:ph],
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'does not include ES if projects are specified, but includes the specified project' do
      filter_params = {
        project_ids: [psh_project.id],
        project_type_codes: [],
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).to include psh_project.id
    end

    it 'does not include any projects if project type codes is empty' do
      filter_params = {
        project_type_codes: [],
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).not_to include psh_project.id
    end
  end

  describe 'a viewable project group containing a project the user cannot see' do
    let!(:other_data_source) { create :source_data_source }
    let!(:invisible_project) { create :grda_warehouse_hud_project, ProjectType: 1, data_source_id: other_data_source.id }
    let!(:project_group) { create :project_group, projects: [psh_project, invisible_project] }

    before do
      user.add_viewable(project_group)
    end

    it 'limits effective_project_ids to the group projects the user can report on' do
      filter = Filters::FilterBase.new(user_id: user.id).update(project_group_ids: [project_group.id])
      expect(filter.effective_project_ids).to eq [psh_project.id]
    end

    it 'limits secondary project group projects to the ones the user can report on' do
      filter = Filters::FilterBase.new(user_id: user.id).update(secondary_project_group_ids: [project_group.id])
      expect(filter.effective_project_ids_from_secondary_project_groups).to eq [psh_project.id]
    end

    it 'limits HudFilterBase effective_project_ids the same way' do
      filter = Filters::HudFilterBase.new(user_id: user.id).update(project_group_ids: [project_group.id])
      expect(filter.effective_project_ids).to eq [psh_project.id]
    end
  end
end
