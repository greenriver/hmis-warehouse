# mark which data sources mess with the PersonalID column
class AddMungedPersonalIdToDataSource < ActiveRecord::Migration
  def change
    cz = GrdaWarehouse::DataSource
    add_column cz.table_name, :munged_personal_id, :boolean, default: false, null: false
  end
end
