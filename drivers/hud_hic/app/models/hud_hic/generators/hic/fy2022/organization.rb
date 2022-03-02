###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Generators::Hic::Fy2022
  class Organization < Base
    include ArelHelper
    include HudReports::Util

    QUESTION_NUMBER = 'Organization'.freeze

    private def question_number
      QUESTION_NUMBER
    end

    private def destination_class
      HudHic::Fy2022::Organization
    end

    private def add
      @generator.organization_scope.find_in_batches(batch_size: 100) do |batch|
        pending_associations = {}
        batch.each do |organization|
          pending_associations[organization] = destination_class.from_attributes_for_hic(organization)
          pending_associations[organization].report_instance_id = @report.id
          pending_associations[organization].data_source_id = organization.data_source_id
        end
        destination_class.import(
          pending_associations.values,
          on_duplicate_key_update: {
            conflict_target: ['"OrganizationID"', :data_source_id, :report_instance_id],
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
      @report.report_cells.joins(universe_members: :organization).exists?
    end
  end
end
