###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddMostRecentMoveInDateToWarehouseClientsProcessed < ActiveRecord::Migration[7.2]
  def change
    add_column :warehouse_clients_processed, :most_recent_move_in_date, :date
  end
end
