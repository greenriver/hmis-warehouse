###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2022
  class Projects < Base
    QUESTION_NUMBER = 'Projects'.freeze

    def self.filter_pending_associations(pending_associations)
      pending_associations
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_NUMBER])

      calculate

      @report.complete(QUESTION_NUMBER)
    end

    private def calculate
      table_name = QUESTION_NUMBER
      metadata = {
        header_row: [
          'Project ID',
          'Project Name',
          'Client Count',
          'Household Count',
          'PITCount from HMIS',
        ],
        row_labels: [],
        first_column: 'A',
        last_column: 'E',
        first_row: 2,
      }

      client_counts = universe.members.distinct.
        group(:project_id, :project_name, :project_hmis_pit_count).
        count(:client_id)
      household_counts = universe.members.distinct.
        group(:project_id, :project_name).
        where(hoh_clause).
        count(:client_id)
      metadata[:last_row] = client_counts.count + 1
      @report.answer(question: table_name).update(metadata: metadata)
      # there will always be at least as many clients as households, so loop over those
      client_counts.each.with_index do |((project_id, project_name, pit_count), client_count), row_num|
        household_count = household_counts[[project_id, project_name]] || 0
        [project_id, project_name, client_count, household_count, pit_count].each.with_index do |value, column_num|
          cell = "#{(column_num + 1).to_csv_column}#{row_num + 2}"

          members = universe.members.where(a_t[:project_id].eq(project_id))
          answer = @report.answer(question: table_name, cell: cell)
          answer.add_members(members)

          answer.update(summary: value)
        end
      end
    end
  end
end
