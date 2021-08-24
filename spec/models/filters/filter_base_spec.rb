require 'rails_helper'

RSpec.describe Filters::FilterBase, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:es_project) { create :grda_warehouse_hud_project, computed_project_type: 1 }
  let!(:psh_project) { create :grda_warehouse_hud_project, computed_project_type: 3 }
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
end
