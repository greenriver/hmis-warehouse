###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Generators::Hic::Fy2021
  class Funder < Base
    include ArelHelper
    include HudReports::Util

    QUESTION_NUMBER = 'Funder'.freeze

    private def question_number
      QUESTION_NUMBER
    end

    private def destination_class
      HudHic::Fy2021::Funder
    end

    private def add
      @generator.funder_scope.preload(:project).find_in_batches(batch_size: 100) do |batch|
        pending_associations = {}
        batch.each do |funder|
          pending_associations[funder] = destination_class.from_attributes_for_hic(funder)
          pending_associations[funder].report_instance_id = @report.id
          pending_associations[funder].data_source_id = funder.data_source_id
        end
        destination_class.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: ['"FunderID"', :data_source_id, :report_instance_id],
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
      @report.report_cells.joins(universe_members: :funder).exists?
    end
  end
end
