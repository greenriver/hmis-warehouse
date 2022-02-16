###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Generators::Hic::Fy2021
  class Project < Base
    include ArelHelper
    include HudReports::Util

    QUESTION_NUMBER = 'Project'.freeze

    private def question_number
      QUESTION_NUMBER
    end

    private def destination_class
      HudHic::Fy2021::Project
    end

    private def add
      @generator.project_scope.preload(:organization).find_in_batches(batch_size: 100) do |batch|
        pending_associations = {}
        batch.each do |project|
          pending_associations[project] = destination_class.from_attributes_for_hic(project)
          # Populate PITCount from actual count of unique clients on this day
          pending_associations[project].PITCount = project.service_history_services.where(date: @generator.filter.on).distinct(:client_id).count
          pending_associations[project].report_instance_id = @report.id
          pending_associations[project].data_source_id = project.data_source_id
        end
        destination_class.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: ['"ProjectID"', :data_source_id, :report_instance_id],
            validate: false,
          },
        )

        # Attach projects to question
        universe_cell = @report.universe(question_number)
        universe_cell.add_universe_members(pending_associations)
      end
      @report.complete(question_number)
    end

    private def populated?
      @report.report_cells.joins(universe_members: :project).exists?
    end
  end
end
