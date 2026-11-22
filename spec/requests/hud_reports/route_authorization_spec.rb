###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD report route authorization', type: :request do
  let(:user) { create(:acl_user) }

  HUD_NAMESPACES = ['hopwa_caper', 'hud_apr', 'hud_data_quality_report', 'hud_hic', 'hud_lsa', 'hud_path_report', 'hud_pit', 'hud_spm_report', 'hud_reports'].freeze

  # Controllers in HUD namespaces that deliberately don't inherit HudReports::BaseController.
  NON_BASE_CONTROLLERS = {
    'HudReports::LsasController' => 'Legacy LSA result pages; authorized by WarehouseReportAuthorization',
    'HudDataQualityReport::LegacyDqsController' => 'Legacy DQ pages over Report rows; authorized by WarehouseReportAuthorization',
    'HudDataQualityReport::LegacyResultsController' => 'Legacy DQ results; has its own authorize_with on the DQ definition',
  }.freeze

  def controller_class_for(route)
    "#{route.defaults[:controller]}_controller".camelize.safe_constantize
  end

  # Routes are enumerated when an example runs, after every driver has loaded its routes.
  def routed_hud_namespace_routes
    Rails.application.routes.routes.select do |route|
      controller = route.defaults[:controller].to_s
      next false unless HUD_NAMESPACES.include?(controller.split('/').first)

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

  before do
    sign_in(user)
    setup_access_control(user, create(:role, can_view_assigned_reports: true), create(:collection))
  end

  it 'routes only HudReports::BaseController subclasses in the HUD namespaces, except the allow-listed controllers' do
    non_base = routed_hud_namespace_routes.map { |route| controller_class_for(route) }.uniq.reject { |klass| klass <= HudReports::BaseController }

    expect(non_base.map(&:name)).to match_array(NON_BASE_CONTROLLERS.keys)
  end

  it 'covers every HUD report driver' do
    expect(hud_routes.map { |r| r.defaults[:controller] }.uniq).to include(
      'hud_apr/aprs', 'hud_apr/apr/cells', 'hud_apr/apr/cells/search_queries', 'hud_data_quality_report/dqs',
      'hud_data_quality_report/questions', 'hud_hic/hics', 'hud_lsa/lsas', 'hud_lsa/lsa_hics', 'hud_path_report/paths',
      'hud_pit/cells', 'hud_spm_report/spms', 'hud_spm_report/legacy_spms', 'hopwa_caper/reports', 'hopwa_caper/cells'
    )
  end

  it 'redirects every routed HUD report action with the not-authorized alert when the definition is not granted' do
    hud_routes.each do |route|
      path = path_for(route)
      public_send(route.verb.downcase, path)
      expect(response).to redirect_to(warehouse_reports_path), "#{route.verb} #{path}"
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.'), "#{route.verb} #{path}"
    end
  end
end
