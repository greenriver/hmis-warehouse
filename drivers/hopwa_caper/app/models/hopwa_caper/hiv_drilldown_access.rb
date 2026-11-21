###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Answers whether a user may see HIV status for every project in a set of HOPWA CAPER rows.
# Drilldown membership reveals HIV status, so access requires the project-level HIV permission on
# each row's project. Restricted clients (see GrdaWarehouse::HiddenClients) do not block access;
# the drilldown presenters redact their rows.
module HopwaCaper
  class HivDrilldownAccess
    def self.for_report(user:, report:, mode: :browse)
      new(
        user: user,
        enrollments: report.hopwa_caper_enrollments,
        services: report.hopwa_caper_services,
        mode: mode,
      )
    end

    def initialize(user:, enrollments:, services:, mode: :browse)
      @user = user
      @enrollments = enrollments
      @services = services
      @mode = mode
    end

    def allowed?
      return @allowed if defined?(@allowed)

      @allowed = compute_allowed
    end

    private

    def compute_allowed
      project_ids = distinct_project_ids
      return false if project_ids.include?(nil)

      @user.policy_context.preload_project_dependencies(project_ids)
      project_ids.all? { |project_id| project_hiv_allowed?(project_id) }
    end

    def project_hiv_allowed?(project_id)
      @user.reporting_policy_for_project(project_id: project_id, mode: @mode).can_view_hiv_status?
    end

    # A service takes its project from its enrollment, so a service without a matching enrollment yields a nil project.
    def distinct_project_ids
      enrollment_project_ids = @enrollments.reorder(nil).distinct.pluck(:project_id)
      service_project_ids = @services.reorder(nil).
        left_outer_joins(:enrollment).
        distinct.
        pluck(HopwaCaper::Enrollment.arel_table[:project_id])

      (enrollment_project_ids + service_project_ids).uniq
    end
  end
end
