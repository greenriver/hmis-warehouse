###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientEnrollmentVisibility
  extend ActiveSupport::Concern

  # Condition on "Enrollment"."id"; the relation it's applied to must already join the Enrollment table.
  # Admits only the visible source enrollments of the given `client`.
  private def visible_enrollment_condition(client)
    GrdaWarehouse::Hud::Enrollment.arel_table[:id].in(visible_enrollment_ids_for(client))
  end

  # Memoized per client; the dashboard rollup builds the condition more than once per request.
  private def visible_enrollment_ids_for(client)
    @visible_enrollment_ids_by_client ||= {}
    @visible_enrollment_ids_by_client[client.id] ||= begin
      current_user.policy_context.preload_client_dependencies([client.id])
      client.source_enrollments.
        preload(:project, client: [:data_source, :destination_client]).
        select { |enrollment| current_user.policy_for(enrollment).can_view? }.
        map(&:id)
    end
  end
end
