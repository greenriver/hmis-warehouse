###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class Base < HudReports::QuestionBase
    protected def build_universe(question_number)
      universe_cell = @report.universe(question_number)

      @generator.client_scope.find_in_batches do |batch|
        pending_associations = {}

        clients_with_enrollments = clients_with_enrollments(batch)

        batch.each do |client|
          pending_associations[client] = yield(client, clients_with_enrollments[client.id])
        end

        report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || []
          }
        )
        universe_cell.add_universe_members(pending_associations)
      end
      universe_cell
    end

    protected def clients_with_enrollments(batch)
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        in_project(@report.project_ids).
        joins(:enrollment).
        preload(enrollment: [:client, :disabilities, :current_living_situations]).
        where(client_id: batch.map(&:id)).
        group_by(&:client_id)
    end

    protected def report_client_universe
      HudApr::Fy2020::AprClient
    end
  end
end