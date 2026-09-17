###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD report access plumbing' do
  let(:definitions) { GrdaWarehouse::WarehouseReports::ReportDefinition }

  describe 'User#can_view_any_reports?' do
    it 'treats a HUD report flag as report access' do
      user = create(:acl_user)
      setup_access_control(user, create(:role, can_view_all_hud_reports: true), create(:collection))

      expect(user.can_view_any_reports?).to be true
    end
  end

  describe 'Role.hud_report_viewer_role' do
    it 'is a system role with only can_view_assigned_reports' do
      role = Role.hud_report_viewer_role
      granted = Role.permissions.select { |permission| role.send(permission) }

      expect(role.system).to be true
      expect(granted).to eq([:can_view_assigned_reports])
    end
  end

  describe 'HudReports::GeneratorBase.report_definition_url' do
    it 'maps a generator to the report definition url of its controller' do
      expect(HudApr::Generators::Apr::Fy2026::Generator.report_definition_url).to eq('hud_reports/aprs')
    end

    it 'distinguishes reports that share a driver' do
      expect(HudApr::Generators::Caper::Fy2026::Generator.report_definition_url).to eq('hud_reports/capers')
    end
  end

  describe 'system groups for reports' do
    before do
      definitions.maintain_report_definitions
      Collection.maintain_system_groups(group: :reports)
      AccessGroup.maintain_system_groups(group: :reports)
    end

    let(:hud_ids) { definitions.hud.pluck(:id) }

    it 'fills the All HUD Reports collection with exactly the HUD report definitions' do
      expect(hud_ids).not_to be_empty
      expect(Collection.system_collection(:hud_reports).report_ids).to match_array(hud_ids)
    end

    it 'fills the All HUD Reports access group with exactly the HUD report definitions' do
      expect(AccessGroup.system_group(:hud_reports).report_ids).to match_array(hud_ids)
    end

    it 'keeps All HMIS Reports as a superset that includes the HUD definitions' do
      hmis_ids = Collection.system_collection(:hmis_reports).report_ids

      expect(hmis_ids).to include(*hud_ids)
      expect(hmis_ids.size).to be > hud_ids.size
    end
  end
end
