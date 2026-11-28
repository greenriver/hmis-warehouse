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

  describe 'GrdaWarehouse::Tasks::GrantAllHudReports.viewer_role' do
    it 'is an editable role with only can_view_assigned_reports' do
      role = GrdaWarehouse::Tasks::GrantAllHudReports.viewer_role
      granted = Role.permissions.select { |permission| role.send(permission) }

      expect(role.system).to be false
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

    it 'defines every HUD definition url in HUD_URLS' do
      expect(hud_urls).to match_array(definitions::HUD_URLS.values)
    end

    it 'maps every HUD_URLS entry to a route' do
      definitions::HUD_URLS.each_value do |url|
        expect(Rails.application.routes.recognize_path("/#{url}")).to include(action: 'index'), url
      end
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
    let(:granted_ids) { definitions.system_granted_hud.pluck(:id) }
    let(:hopwa_id) { definitions.find_by!(url: definitions.hud_url(:hopwa_capers)).id }

    it 'fills the All HUD Reports collection with every HUD definition except opt-in ones' do
      expect(granted_ids).not_to be_empty
      expect(Collection.system_collection(:hud_reports).report_ids).to match_array(granted_ids)
      expect(Collection.system_collection(:hud_reports).report_ids).to include(definitions.find_by!(url: definitions.hud_url(:aprs)).id)
    end

    it 'fills the All HUD Reports access group with every HUD definition except opt-in ones' do
      expect(AccessGroup.system_group(:hud_reports).report_ids).to match_array(granted_ids)
    end

    it 'keeps HOPWA CAPER out of the All HUD Reports collection and access group' do
      expect(Collection.system_collection(:hud_reports).report_ids).not_to include(hopwa_id)
      expect(AccessGroup.system_group(:hud_reports).report_ids).not_to include(hopwa_id)
    end

    it 'keeps HOPWA CAPER out of the All HMIS Reports collection and access group' do
      expect(Collection.system_collection(:hmis_reports).report_ids).not_to include(hopwa_id)
      expect(AccessGroup.system_group(:hmis_reports).report_ids).not_to include(hopwa_id)
    end

    it 'removes HOPWA CAPER from an existing All HUD Reports collection and access group' do
      Collection.system_collection(:hud_reports).set_viewables({ reports: hud_ids })
      AccessGroup.system_group(:hud_reports).set_viewables({ reports: hud_ids })
      expect(Collection.system_collection(:hud_reports).report_ids).to include(hopwa_id)
      expect(AccessGroup.system_group(:hud_reports).report_ids).to include(hopwa_id)

      Collection.maintain_system_groups(group: :reports)
      AccessGroup.maintain_system_groups(group: :reports)

      expect(Collection.system_collection(:hud_reports).report_ids).to match_array(granted_ids)
      expect(AccessGroup.system_group(:hud_reports).report_ids).to match_array(granted_ids)
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
