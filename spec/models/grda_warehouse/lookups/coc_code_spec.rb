require 'rails_helper'

RSpec.describe GrdaWarehouse::Lookups::CocCode, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:project_1) { create :grda_warehouse_hud_project, ProjectType: 1, OrganizationID: organization.OrganizationID }
  let!(:project_coc_coc_1) { create :grda_warehouse_hud_project_coc, ProjectID: project_1.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-500' }
  let!(:project_2) { create :grda_warehouse_hud_project, ProjectType: 3, OrganizationID: organization.OrganizationID }
  let!(:project_coc_coc_2) { create :grda_warehouse_hud_project_coc, ProjectID: project_2.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-501' }
  let!(:project_3) { create :grda_warehouse_hud_project, ProjectType: 3, OrganizationID: organization.OrganizationID }
  let!(:project_coc_coc_3) { create :grda_warehouse_hud_project_coc, ProjectID: project_3.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-502' }
  let!(:user) { create :user }
  let!(:coc_codes) { create_list :lookup_coc, 5 }
  let(:expected_cocs) { ['XX-500', 'XX-501'].sort }
  before do
    # User should have access to:
    # * XX-500 through project 1
    # * XX-501 through a CoC code assignment
    # * no access to XX-502
    user.add_viewable(project_1)
    user.coc_codes = ['XX-501']
  end

  it 'user can view 2 projects' do
    scope = GrdaWarehouse::Hud::Project.viewable_by(user)
    expect(scope.count).to eq(2)
  end

  it 'CoC Code viewable_by includes expected CoCs' do
    scope = GrdaWarehouse::Lookups::CocCode.viewable_by(user)
    expect(scope.count).to eq(2)
    expect(scope.pluck(:coc_code).sort).to eq(expected_cocs)
  end

  it 'Filter only presents expected CoC Codes' do
    filter = Filters::FilterBase.new(user_id: user.id)
    expect(filter.coc_code_options_for_select(user: user).map(&:last).sort).to eq(expected_cocs)
  end
end
