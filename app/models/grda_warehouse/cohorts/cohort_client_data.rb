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
  class CohortClientData < GrdaWarehouseBase
    # Maintains cohort data by deleting existing records and inserting updated data.
    #
    # @param cohort [Cohort] The cohort for which client data should be maintained.
    # @return [void]
    def self.maintain_data(cohort)
      transaction do
        where(cohort_id: cohort.id).delete_all
        cohort.cohort_clients.joins(:client).preload(*cohort.preloads).find_in_batches do |client_batch|
          batch = []
          client_batch.each do |client|
            cohort.active_columns.each do |col|
              next if col.class.in?(cohort.class.excluded_from_analytics)

              col.cohort = cohort
              col.cohort_client = client
              col.current_user = User.system_user
              batch << {
                cohort_id: cohort.id,
                cohort_client_id: client.id,
                data_type: col.analytics_data_type,
                column_name: col.column,
                value_integer: nil,
                value_boolean: nil,
                value_string: nil,
                value_text: nil,
                value_date: nil,
                value_json: nil,
              }.merge(text_value(col))
            end
          end
          insert_all!(batch) if batch.present?
        end
      end
    end

    # Generates a hash containing the appropriate value for the given column and client.
    #
    # @param column [Column] The column for which the value should be determined.
    # @param client [CohortClient] The cohort client whose data is being processed.
    # @return [Hash{Symbol => Object}] A hash containing the column value for the client.
    def self.text_value(column)
      key = "value_#{column.analytics_data_type}".to_sym
      value = column.analytics_value
      { key => value }
    end
  end
end
