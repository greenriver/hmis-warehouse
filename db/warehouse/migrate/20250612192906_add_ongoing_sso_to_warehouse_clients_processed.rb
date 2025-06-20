###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddOngoingSsoToWarehouseClientsProcessed < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouse_clients_processed, :cohorts_ongoing_enrollments_sso, :jsonb
  end
end
