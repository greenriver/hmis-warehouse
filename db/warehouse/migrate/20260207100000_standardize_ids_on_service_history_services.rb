###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class StandardizeIdsOnServiceHistoryServices < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  COLUMNS = %i[client_id service_history_enrollment_id].freeze

  def up
    return unless Rails.env.development? || Rails.env.test?

    safety_assured do
      execute('DROP MATERIALIZED VIEW IF EXISTS service_history_services_materialized')
      drop_view 'service_history'
      # Alter the parent partitioned table
      COLUMNS.each do |col|
        safety_assured do
          execute "ALTER TABLE service_history_services ALTER COLUMN #{col} TYPE bigint"
        end
      end

      GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
      create_view 'service_history'
    end
  end

end
