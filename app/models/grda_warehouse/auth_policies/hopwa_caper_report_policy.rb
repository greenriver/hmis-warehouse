###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Drilldown membership reveals HIV status. Get it with `policy_for(report, policy_class: GrdaWarehouse::AuthPolicies::HopwaCaperReportPolicy)`.
class GrdaWarehouse::AuthPolicies::HopwaCaperReportPolicy < GrdaWarehouse::AuthPolicies::HudReportPolicy
  memoize def can_view_drilldowns?
    can_view? && HopwaCaper::HivDrilldownAccess.for_report(user: user, report: resource, mode: :browse).allowed?
  end

  def can_view_cell?(enrollments:, services:, mode:)
    can_view? && HopwaCaper::HivDrilldownAccess.new(user: user, enrollments: enrollments, services: services, mode: mode).allowed?
  end

  protected

  def validate_resource!(arg)
    super
    return if arg.report_definition_url == GrdaWarehouse::WarehouseReports::ReportDefinition.hud_url(:hopwa_capers)

    raise ArgumentError, "Expected a HOPWA CAPER report, got #{arg.report_name}"
  end
end
