###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Filters HMIS enrollments used when resolving enrollment-scoped CE match fields
  # (e.g. PSDE HUD table data, CDEs on custom assessments linked to enrollments).
  #
  # Lookback window and project group come from global +Hmis::Ce.configuration+.
  #
  # Join path: destination client → source clients → enrollments.
  class EnrollmentEligibilityScope
    include Hmis::Concerns::HmisArelHelper

    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date.to_date
      @configuration = configuration
    end

    # @param destination_client_ids [Array<Integer>] destination client ids
    # @return [ActiveRecord::Relation<Hmis::Hud::Enrollment>]
    def call(destination_client_ids)
      destination_client_ids = Array(destination_client_ids)
      return Hmis::Hud::Enrollment.none if destination_client_ids.empty?

      # Scope enrollments to the destination clients
      scope = Hmis::Hud::Enrollment.joins(client: :warehouse_client_source).
        where(wc_t[:destination_id].in(destination_client_ids))

      # Filter down enrollments to the project group, if specified
      scope = apply_project_group_filter(scope)

      # Filter down enrollments to those overlapping the lookback window, if specified
      scope = apply_lookback_filter(scope)

      scope
    end

    private

    def apply_project_group_filter(scope)
      project_group = @configuration.eligibility_project_group
      return scope if project_group.nil?

      scope.with_project(project_group.effective_project_ids)
    end

    def apply_lookback_filter(scope)
      lookback_months = @configuration.eligibility_lookback_months
      # 0 lookback months means: only look at data from currently open enrollments.
      # Note: intentionally do not use open_on_date scope, which includes enrollments whose ExitDate equals current_date.
      return scope.open_including_wip if lookback_months.zero?

      window_start = @current_date - lookback_months.months
      scope.open_during_range(window_start..@current_date)
    end
  end
end
