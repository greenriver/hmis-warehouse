###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Answers whether a user may see HIV status for every client in a set of HOPWA CAPER rows.
# Drilldown membership reveals HIV status, so access requires the project-level HIV permission on
# each row's project and no HMIS restriction on any row's client.
#
# Project permissions do not depend on the client, and restriction does not depend on the
# project, so projects and clients are checked separately rather than as pairs.
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
      pairs = project_client_pairs
      project_ids = pairs.map(&:first).uniq
      return false if project_ids.include?(nil)

      client_ids = pairs.map(&:last).uniq.compact
      policy_context = @user.policy_context
      policy_context.preload_project_dependencies(project_ids)
      policy_context.preload_client_restrictions(client_ids)

      project_ids.all? { |project_id| project_hiv_allowed?(project_id) } &&
        client_ids.none? { |client_id| policy_context.client_restricted?(client_id) }
    end

    def project_hiv_allowed?(project_id)
      @user.reporting_policy_for_project(project_id: project_id, mode: @mode).can_view_hiv_status?
    end

    # Distinct [project_id, destination_client_id] pairs from both relations. A service takes its
    # project from its enrollment, so a service without a matching enrollment yields a nil project.
    def project_client_pairs
      enrollment_pairs = @enrollments.reorder(nil).distinct.pluck(:project_id, :destination_client_id)

      service_table = HopwaCaper::Service.arel_table
      enrollment_table = HopwaCaper::Enrollment.arel_table
      service_pairs = @services.reorder(nil).
        left_outer_joins(:enrollment).
        distinct.
        pluck(enrollment_table[:project_id], service_table[:destination_client_id])

      (enrollment_pairs + service_pairs).uniq
    end
  end
end
