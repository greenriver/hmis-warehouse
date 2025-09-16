###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Lookups::CocCode, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization, data_source_id: data_source.id }
  let!(:project_1) { create :grda_warehouse_hud_project, ProjectType: 1, OrganizationID: organization.OrganizationID, data_source_id: data_source.id }
  let!(:project_coc_coc_1) { create :grda_warehouse_hud_project_coc, ProjectID: project_1.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-500' }
  let!(:project_2) { create :grda_warehouse_hud_project, ProjectType: 3, OrganizationID: organization.OrganizationID, data_source_id: data_source.id }
  let!(:project_coc_coc_2) { create :grda_warehouse_hud_project_coc, ProjectID: project_2.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-501' }
  let!(:project_3) { create :grda_warehouse_hud_project, ProjectType: 3, OrganizationID: organization.OrganizationID, data_source_id: data_source.id }
  let!(:project_coc_coc_3) { create :grda_warehouse_hud_project_coc, ProjectID: project_3.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-502' }
  let!(:user) { create :user }
  let(:expected_cocs) { ['XX-500', 'XX-501'].sort }
  describe 'legacy permissions' do
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

  describe 'access control permissions' do
    let!(:acl_user) { create :acl_user }
    let!(:role) { create :assigned_report_viewer }
    let!(:user_group) { create :user_group }
    let!(:collection) { create :collection }
    let!(:project_access_control) { create :access_control, role: role, collection: collection, user_group: user_group }

    before do
      # User should have access to:
      # * XX-500 through project 1
      # * XX-501 through a CoC code assignment
      # * no access to XX-502
      collection.set_viewables({ projects: [project_1.id], coc_codes: GrdaWarehouse::Lookups::CocCode.where(coc_code: ['XX-501']).pluck(:id) })
      user_group.add(acl_user)
    end

    it 'user can view 2 projects' do
      scope = GrdaWarehouse::Hud::Project.viewable_by(acl_user, permission: :can_view_assigned_reports)
      expect(scope.count).to eq(2)
    end

    it 'CoC Code viewable_by includes expected CoCs' do
      scope = GrdaWarehouse::Lookups::CocCode.viewable_by(acl_user, permission: :can_view_assigned_reports)
      expect(scope.count).to eq(2)
      expect(scope.pluck(:coc_code).sort).to eq(expected_cocs)
    end

    it 'Filter only presents expected CoC Codes' do
      filter = Filters::FilterBase.new(user_id: acl_user.id)
      expect(filter.coc_code_options_for_select(user: acl_user, permission: :can_view_assigned_reports).map(&:last).sort).to eq(expected_cocs)
    end
  end
end
