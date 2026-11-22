###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD report route authorization', type: :request do
  def hud_namespaces
    ['hopwa_caper', 'hud_apr', 'hud_data_quality_report', 'hud_hic', 'hud_lsa', 'hud_path_report', 'hud_pit', 'hud_spm_report', 'hud_reports']
  end

  # Controllers in HUD namespaces that deliberately don't inherit HudReports::BaseController.
  def non_base_controllers
    {
      'HudReports::LsasController' => 'Legacy LSA result pages; authorized by WarehouseReportAuthorization',
      'HudDataQualityReport::LegacyDqsController' => 'Legacy DQ pages over Report rows; authorized by WarehouseReportAuthorization',
      'HudDataQualityReport::LegacyResultsController' => 'Legacy DQ results; has its own authorize_with on the DQ definition',
    }
  end

  def controller_class_for(route)
    "#{route.defaults[:controller]}_controller".camelize.safe_constantize
  end

  # Routes are enumerated when an example runs, after every driver has loaded its routes.
  def routed_hud_namespace_routes
    Rails.application.routes.routes.select do |route|
      controller = route.defaults[:controller].to_s
      next false unless hud_namespaces.include?(controller.split('/').first)

      controller_class = controller_class_for(route)
      controller_class.is_a?(Class) && controller_class.action_methods.include?(route.defaults[:action])
    end
  end

  def hud_routes
    routed_hud_namespace_routes.select { |route| controller_class_for(route) <= HudReports::BaseController }
  end

  def path_for(route)
    route.format(route.required_parts.index_with('1'))
  end

  # Independent of the controllers' own related_report, so a drilldown pointed at the wrong definition is caught.
  def expected_definition_url(route)
    patterns = {
      /\Ahud_spm_report\// => :spms,
      /\Ahud_pit\// => :pits,
      /\Ahud_path_report\// => :paths,
      /\Ahud_lsa\// => :lsas,
      /\Ahud_hic\// => :hics,
      /\Ahud_data_quality_report\// => :dqs,
      /\Ahud_apr\/dqs\z|\Ahud_apr\/dq\// => :dqs,
      /\Ahud_apr\/aprs\z|\Ahud_apr\/apr\// => :aprs,
      /\Ahud_apr\/capers\z|\Ahud_apr\/caper\// => :capers,
      /\Ahud_apr\/ce_aprs\z|\Ahud_apr\/ce_apr\// => :ce_aprs,
      /\Ahopwa_caper\// => :hopwa_capers,
    }
    key = patterns.find { |pattern, _| pattern.match?(route.defaults[:controller]) }&.last
    GrdaWarehouse::WarehouseReports::ReportDefinition.hud_url(key) if key
  end

  def own_definition_urls(route)
    controller_class_for(route).new.send(:related_report).pluck(:url)
  end

  # Grants every HUD definition except the given ones, so a denial can only come from the route's own definition.
  def sign_in_with_hud_grant_excluding(own_urls)
    other_ids = GrdaWarehouse::WarehouseReports::ReportDefinition.
      where(url: GrdaWarehouse::WarehouseReports::ReportDefinition::HUD_URLS.values - own_urls).
      pluck(:id)
    collection = create(:collection, collection_type: 'Reports')
    collection.set_viewables(reports: other_ids)
    granted_user = create(:acl_user)
    setup_access_control(granted_user, create(:role, can_view_assigned_reports: true), collection)
    sign_in(granted_user)
  end

  it 'routes only HudReports::BaseController subclasses in the HUD namespaces, except the allow-listed controllers' do
    non_base = routed_hud_namespace_routes.map { |route| controller_class_for(route) }.uniq.reject { |klass| klass <= HudReports::BaseController }

    expect(non_base.map(&:name)).to match_array(non_base_controllers.keys)
  end

  it 'covers every HUD report driver' do
    expect(hud_routes.map { |r| r.defaults[:controller] }.uniq).to include(
      'hud_apr/aprs', 'hud_apr/apr/cells', 'hud_apr/apr/cells/search_queries', 'hud_data_quality_report/dqs',
      'hud_data_quality_report/questions', 'hud_hic/hics', 'hud_lsa/lsas', 'hud_lsa/lsa_hics', 'hud_path_report/paths',
      'hud_pit/cells', 'hud_spm_report/spms', 'hud_spm_report/legacy_spms', 'hopwa_caper/reports', 'hopwa_caper/cells'
    )
  end

  it 'redirects every routed HUD report action when only the other HUD definitions are granted' do
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions

    hud_routes.each do |route|
      own_urls = own_definition_urls(route)
      expect(own_urls).to be_present, "#{route.defaults[:controller]}##{route.defaults[:action]} has no definition"
      expect(own_urls).to eq([expected_definition_url(route)]), "#{route.defaults[:controller]} maps to #{own_urls.inspect}"
    end

    hud_routes.group_by { |route| own_definition_urls(route) }.each do |own_urls, routes|
      sign_in_with_hud_grant_excluding(own_urls)

      routes.each do |route|
        path = path_for(route)
        label = "#{route.verb} #{path} (own definition #{own_urls.join(', ')})"
        public_send(route.verb.downcase, path)
        expect(response).to redirect_to(warehouse_reports_path), label
        expect(flash[:alert]).to eq('Sorry you are not authorized to do that.'), label
      end
    end
  end
end
