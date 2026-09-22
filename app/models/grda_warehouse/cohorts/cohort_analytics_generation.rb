###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/warehouse/cohorts.md
# This model holds metadata around runs of maintaining intermediate data in the shape cohort data
# is expected to take in the future.  Additionally, this model provides the logic for converting
# existing cohort data into the expected shape.
module GrdaWarehouse::Cohorts
  class CohortAnalyticsGeneration < GrdaWarehouseBase
    # @return [Boolean] false if another run held the lock and this one did no work
    def self.maintain_cohort_intermediate_data
      did_run = false
      with_lock do
        maintain_titles
        maintain_tabs
        maintain_data
        did_run = true
      end
      did_run
    end

    private_class_method def self.with_lock(&block)
      GrdaWarehouseBase.with_advisory_lock(name.demodulize, timeout_seconds: 0, &block)
    end

    def self.maintain_titles
      act_on_each_cohort(__method__) do |cohort|
        GrdaWarehouse::Cohorts::CohortColumnMetadata.maintain_titles(cohort)
        GrdaWarehouse::Cohorts::CohortClientTab.maintain_tabs(cohort)
      end
    end

    def self.maintain_tabs
      act_on_each_cohort(__method__) do |cohort|
        GrdaWarehouse::Cohorts::CohortClientTab.maintain_tabs(cohort)
      end
    end

    def self.maintain_data
      act_on_each_cohort(__method__) do |cohort|
        GrdaWarehouse::Cohorts::CohortClientData.maintain_data(cohort)
      end
    end

    # yield or each cohort and log processing time
    def self.act_on_each_cohort(action)
      GrdaWarehouse::Cohort.find_each do |cohort|
        generator = create!(
          cohort_id: cohort.id,
          started_at: Time.current,
          process_name: action,
        )
        yield(cohort)
        generator.update!(completed_at: Time.current)
      end
    end
  end
end
