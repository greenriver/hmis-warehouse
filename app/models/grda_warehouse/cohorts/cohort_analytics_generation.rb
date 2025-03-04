###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This model holds metadata around runs of maintaining intermediate data in the shape cohort data
# is expected to take in the future.  Additionally, this model provides the logic for converting
# existing cohort data into the expected shape.
module GrdaWarehouse::Cohorts
  class CohortAnalyticsGeneration < GrdaWarehouseBase
    def self.maintain_cohort_intermediate_data
      maintain_titles
      maintain_tabs
      maintain_data
    end

    def self.maintain_titles
      GrdaWarehouse::Cohort.find_each do |cohort|
        generator = create!(
          cohort_id: cohort.id,
          started_at: Time.current,
          process_name: __method__,
        )
        GrdaWarehouse::Cohorts::CohortColumnTitle.maintain_titles(cohort)
        GrdaWarehouse::Cohorts::CohortClientTab.maintain_tabs(cohort)
        generator.update!(completed_at: Time.current)
      end
    end

    def self.maintain_tabs
      GrdaWarehouse::Cohort.find_each do |cohort|
        generator = create!(
          cohort_id: cohort.id,
          started_at: Time.current,
          process_name: __method__,
        )
        GrdaWarehouse::Cohorts::CohortClientTab.maintain_tabs(cohort)
        generator.update!(completed_at: Time.current)
      end
    end

    def self.maintain_data
      GrdaWarehouse::Cohort.find_each do |cohort|
        generator = create!(
          cohort_id: cohort.id,
          started_at: Time.current,
          process_name: __method__,
        )
        GrdaWarehouse::Cohorts::CohortClientData.maintain_data(cohort)
        generator.update!(completed_at: Time.current)
      end
    end
  end
end
