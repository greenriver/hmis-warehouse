class RemoveStaffColumnFromHmisAssessment < ActiveRecord::Migration
  def change
    table = GrdaWarehouse::HMIS::Assessment.table_name
    remove_column table, :staff_id
  end
end
