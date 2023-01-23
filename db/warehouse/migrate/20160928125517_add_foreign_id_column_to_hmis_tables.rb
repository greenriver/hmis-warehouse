class AddForeignIdColumnToHmisTables < ActiveRecord::Migration[4.2]
  def change
    [ GrdaWarehouse::Hmis::Assessment, GrdaWarehouse::Hmis::StaffXClient ].each do |model|
      add_column model.table_name, :source_class, :string
      add_column model.table_name, :source_id, :string
    end
  end
end
