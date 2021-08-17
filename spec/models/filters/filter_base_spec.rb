require 'rails_helper'

RSpec.describe Filters::FilterBase, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:es_project) { create :grda_warehouse_hud_project, computed_project_type: 1 }
  let!(:psh_project) { create :grda_warehouse_hud_project, computed_project_type: 3 }
  let!(:user) { create :user }

  before :each do
    user.add_viewable(data_source)
  end

  it 'does not include any projects if nothing is specified' do
    filter_params = {
    }
    filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
    expect(filter.effective_project_ids).not_to include psh_project.id
    expect(filter.effective_project_ids).not_to include es_project.id
  end

  it 'includes the PSH if type ph is specified' do
    filter_params = {
      project_type_codes: [:ph],
    }
    filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
    expect(filter.effective_project_ids).to include psh_project.id
    expect(filter.effective_project_ids).not_to include es_project.id
  end

  it 'does not include ES if projects are specified, but includes the specified project' do
    filter_params = {
      project_ids: [psh_project.id],
    }
    filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
    expect(filter.effective_project_ids).not_to include es_project.id
    expect(filter.effective_project_ids).to include psh_project.id
  end

  it 'defaults to homeless projects if project type codes is empty' do
    filter_params = {
      project_type_codes: [],
    }
    filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
    expect(filter.effective_project_ids).to include es_project.id
    expect(filter.effective_project_ids).not_to include psh_project.id
  end
end
