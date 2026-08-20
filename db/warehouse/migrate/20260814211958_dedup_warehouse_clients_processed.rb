###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DedupWarehouseClientsProcessed < ActiveRecord::Migration[8.1]
  def up
    dupes = GrdaWarehouse::WarehouseClientsProcessed.
      group(:client_id, :routine).
      having('count(*) > 1').
      count

    dupes.each_key do |client_id, routine|
      scope = GrdaWarehouse::WarehouseClientsProcessed.
        where(client_id: client_id, routine: routine).
        order(updated_at: :asc, id: :asc)
      keeper = scope.last
      scope.where.not(id: keeper.id).delete_all
    end
  end
end
