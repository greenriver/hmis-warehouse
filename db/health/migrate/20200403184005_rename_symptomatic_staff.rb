class RenameSymptomaticStaff < ActiveRecord::Migration[5.2]
  def change
    rename_column :tracing_staffs, :symtomatic, :symptomatic
  end
end
