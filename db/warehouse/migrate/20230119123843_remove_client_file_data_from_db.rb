class RemoveClientFileDataFromDb < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::File.with_deleted.where(type: 'GrdaWarehouse::ClientFile').where.not(content: nil).update_all(content: nil)
  end
end
