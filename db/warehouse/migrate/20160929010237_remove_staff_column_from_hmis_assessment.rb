class RemoveStaffColumnFromHmisAssessment < ActiveRecord::Migration[4.2]
  def change
    table = GrdaWarehouse::Hmis::Assessment.table_name
    remove_column table, :staff_id
  end
end
