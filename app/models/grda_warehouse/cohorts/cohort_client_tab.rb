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
  class CohortClientTab < GrdaWarehouseBase
    def self.maintain_tabs(cohort)
      transaction do
        where(cohort_id: cohort.id).delete_all
        cohort.cohort_tabs.each do |tab|
          batch = cohort.clients_for_tab(User.system_user, tab.name, tab).pluck(:id).map do |client_id|
            {
              cohort_id: cohort.id,
              cohort_client_id: client_id,
              tab_name: tab.name,
            }
          end
          insert_all!(batch) if batch.present?
        end
      end
    end
  end
end
