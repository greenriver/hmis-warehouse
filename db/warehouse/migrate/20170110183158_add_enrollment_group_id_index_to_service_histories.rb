class AddEnrollmentGroupIdIndexToServiceHistories < ActiveRecord::Migration
  def change
    add_index GrdaWarehouse::ServiceHistory.table_name, :enrollment_group_id
  end
end
