class AddMissingForeignKeyConstraintsOnPartition < ActiveRecord::Migration
  def change
    # moved to an earlier migration to keep all of the logic together.
    # enrollment_table = GrdaWarehouse::ServiceHistoryEnrollment.table_name
    # GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, name|
    #   add_foreign_key name, enrollment_table, on_delete: :cascade
    # end
    # name = GrdaWarehouse::ServiceHistoryService.remainder_table
    # add_foreign_key name, enrollment_table, on_delete: :cascade
  end
end
