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
    let(:registry) { Rails.application.config.hud_reports }
    let(:hud_urls) do
      definitions.maintain_report_definitions
      definitions.hud.pluck(:url)
    end

    # The LSA generator is a ReportInstance, not a GeneratorBase; its controller
    # names the definition directly, so only the registry check applies to it.
    it 'resolves every registered generator to a seeded HUD definition' do
      generators = registry.keys.map(&:constantize).select { |klass| klass < HudReports::GeneratorBase }
      registry_urls = registry.values.map { |entry| Rails.application.routes.url_helpers.public_send(entry[:helper]).delete_prefix('/') }

      expect(generators).not_to be_empty
      expect(generators.map(&:report_definition_url).uniq).to all(be_in(hud_urls))
      expect(registry_urls.uniq).to all(be_in(hud_urls))
    end

    it 'distinguishes reports that share a driver' do
      expect(HudApr::Generators::Caper::Fy2026::Generator.report_definition_url).to eq('hud_reports/capers')
      expect(HudApr::Generators::Apr::Fy2026::Generator.report_definition_url).to eq('hud_reports/aprs')
    end

    # Drilldown controllers and PDF exports gate on whichever generator of the family
    # `possible_generator_classes` yields first, so a family spanning two definitions
    # would gate the whole family on an arbitrary one of them.
    it 'maps every fiscal year of a report family to one definition url' do
      families = registry.group_by { |name, _| name.sub(/::Fy\d+::\w+\z/, '') }

      expect(families['HudApr::Generators::Apr'].size).to be > 1
      families.each do |family, entries|
        urls = entries.map { |_, entry| Rails.application.routes.url_helpers.public_send(entry[:helper]).delete_prefix('/') }.uniq

        expect(urls.size).to eq(1), "#{family} spans #{urls.inspect}"
      end
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

    it 'keeps HUD definitions out of All HMIS Reports so that grant does not carry HUD access' do
      expect(Collection.system_collection(:hmis_reports).report_ids).not_to be_empty
      expect(Collection.system_collection(:hmis_reports).report_ids & hud_ids).to be_empty
      expect(AccessGroup.system_group(:hmis_reports).report_ids & hud_ids).to be_empty
    end

    it 'still gives the system user every report, HUD included' do
      expect(Collection.system_collection(:system_user).report_ids).to include(*hud_ids)
    end
  end
end
