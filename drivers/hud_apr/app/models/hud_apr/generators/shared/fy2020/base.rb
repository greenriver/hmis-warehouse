###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class Base < HudReports::QuestionBase
    def run!
      run_question!
    rescue Exception => e
      @report.answer(question: self.class.question_number).update(error_messages: e.full_message)
      raise e
    end

    protected def build_universe(question_number, before_block: nil, after_block: nil)
      universe_cell = @report.universe(question_number)

      @generator.client_scope.find_in_batches do |batch|
        pending_associations = {}

        clients_with_enrollments = clients_with_enrollments(batch)

        before_block.call(clients_with_enrollments) if before_block.present?

        batch.each do |client|
          pending_associations[client] = yield(client, clients_with_enrollments[client.id])
        end

        report_client_universe.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :report_instance_id],
            columns: pending_associations.values.first&.changes&.keys || [],
          },
        )

        after_block.call(clients_with_enrollments, pending_associations) if after_block.present?

        universe_cell.add_universe_members(pending_associations)
      end
      universe_cell
    end

    protected def clients_with_enrollments(batch)
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        joins(:enrollment).
        preload(enrollment: [:client, :disabilities, :current_living_situations, :services]).
        where(client_id: batch.map(&:id))
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope.group_by(&:client_id)
    end

    protected def report_client_universe
      HudApr::Fy2020::AprClient
    end

    protected def report_living_situation_universe
      HudApr::Fy2020::AprLivingSituation
    end
  end
end
