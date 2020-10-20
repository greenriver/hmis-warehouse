class AddCpAssignmentPlanToCps < ActiveRecord::Migration[5.2]
  def change
    add_column :cps, :cp_assignment_plan, :string
  end
end
