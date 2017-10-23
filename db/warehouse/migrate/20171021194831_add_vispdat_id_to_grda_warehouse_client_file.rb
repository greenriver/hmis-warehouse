class AddVispdatIdToGrdaWarehouseClientFile < ActiveRecord::Migration
  def change
    add_reference :files, :vispdat, index: true, foreign_key: true
  end
end
