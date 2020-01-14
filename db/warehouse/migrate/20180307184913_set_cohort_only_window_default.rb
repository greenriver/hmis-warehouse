class SetCohortOnlyWindowDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default :cohorts, :only_window, :true
  end
end
