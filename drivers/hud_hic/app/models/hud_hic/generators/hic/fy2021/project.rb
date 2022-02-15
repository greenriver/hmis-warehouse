###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Generators::Hic::Fy2021
  class Project < ::HudReports::QuestionBase
    include ArelHelper
    include HudReports::Util

    QUESTION_NUMBER = 'Project'.freeze

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_NUMBER])
      universe

      header_row = HudHic::Fy2021::Project.hmis_configuration(version: '2022').keys
      cell_columns = ('A'..header_row.count.to_csv_column).to_a
      universe.members.to_a.each_with_index do |row, row_index|
        header_row.each_with_index do |header, column_index|
          value = row[header]
          cell_name = cell_columns[column_index] + (row_index + 1).to_s
          @report.answer(question: QUESTION_NUMBER, cell: cell_name).update(summary: value)
        end
      end

      metadata = {
        header_row: header_row,
        row_labels: [],
        first_column: 'A',
        last_column: header_row.count.to_csv_column,
        first_row: 2,
        last_row: universe.members.count + 1,
      }
      @report.answer(question: QUESTION_NUMBER).update(metadata: metadata)
    end

    private def universe
      add_projects unless projects_populated?

      @universe ||= @report.universe(self.class.question_number)
    end

    private def add_projects
      @generator.project_scope.preload(:organization).find_in_batches(batch_size: 100) do |batch|
        pending_associations = {}
        batch.each do |project|
          pending_associations[project] = HudHic::Fy2021::Project.from_attributes_for_hic(project)
          # Populate PITCount from actual count of unique clients on this day
          pending_associations[project].PITCount = project.service_history_services.where(date: @generator.filter.on).distinct(:client_id).count
          pending_associations[project].report_instance_id = @report.id
          pending_associations[project].data_source_id = project.data_source_id
        end
        HudHic::Fy2021::Project.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: ['"ProjectID"', :data_source_id, :report_instance_id],
            validate: false,
          },
        )

        # Attach projects to question
        universe_cell = @report.universe(QUESTION_NUMBER)
        universe_cell.add_universe_members(pending_associations)
      end
      @report.complete(QUESTION_NUMBER)
    end

    private def projects_populated?
      @report.report_cells.joins(universe_members: :project).exists?
    end
  end
end
