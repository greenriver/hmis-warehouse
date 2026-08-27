###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddUniqueIndexToWarehouseClientsProcessed < ActiveRecord::Migration[8.1]
  def change
    # Omit `algorithm: :concurrently`, so the migration runs in one transaction.
    # This avoids needing disable_ddl_transaction! which we've had issues with in the past.
    safety_assured do
      add_index(
        :warehouse_clients_processed,
        [:client_id, :routine],
        unique: true,
        name: :uidx_warehouse_clients_processed_on_client_id_and_routine,
      )
    end
  end
end
