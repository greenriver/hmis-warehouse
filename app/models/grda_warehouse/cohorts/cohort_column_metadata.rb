###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This model is an intermediate model used to hold data generated from existing cohorts.
# The table is maintained by a script and is in the shape we expect to exist after the
# next cohort rewrite.
module GrdaWarehouse::Cohorts
  class CohortColumnMetadata < GrdaWarehouseBase
    def self.maintain_titles(cohort)
      transaction do
        where(cohort_id: cohort.id).delete_all
        batch = cohort.active_columns.filter_map do |col|
          next if col.class.in?(cohort.class.excluded_from_analytics)

          {
            cohort_id: cohort.id,
            data_type: col.analytics_data_type,
            name: col.column,
            title: col.title,
            description: col.description,
          }
        end
        insert_all!(batch) if batch.present?
      end
    end
  end
end
