###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::SystemCohorts
  class Base < GrdaWarehouse::Cohort
    def self.update_system_cohorts
      cohort_classes.each do |config_key, clazz|
        next unless GrdaWarehouse::Config.get(config_key)

        clazz.first_or_create! do |cohort|
          cohort.name = cohort.cohort_name
          cohort.system_cohort = true
        end.sync
      end
    end

    def self.cohort_classes
      @cohort_classes ||= {
        currently_homeless_cohort: GrdaWarehouse::SystemCohorts::CurrentlyHomeless,
      }.freeze
    end
  end
end
