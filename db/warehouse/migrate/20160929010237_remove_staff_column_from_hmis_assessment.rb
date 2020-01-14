class RemoveStaffColumnFromHmisAssessment < ActiveRecord::Migration[4.2]
  def change
    table = GrdaWarehouse::HMIS::Assessment.table_name
    remove_column table, :staff_id
  end
end
