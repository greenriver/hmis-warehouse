require 'rails_helper'

RSpec.describe Filters::FilterBase, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:es_project) { create :grda_warehouse_hud_project, computed_project_type: 1, OrganizationID: organization.OrganizationID }
  let!(:psh_project) { create :grda_warehouse_hud_project, ProjectType: 3, computed_project_type: 3, OrganizationID: organization.OrganizationID }
  let!(:user) { create :user }
  # filter permissions are governed by the projects you can see in the reporting context
  let!(:reporting_role) { create :role, can_view_assigned_reports: true }
  let!(:ds_entity_group) { create :access_group }

  before :each do
    ds_entity_group.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(user, reporting_role, ds_entity_group)
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
end
