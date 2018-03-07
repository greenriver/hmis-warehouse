class SetCohortOnlyWindowDefault < ActiveRecord::Migration
  def change
    change_column_default :cohorts, :only_window, :true
  end
end
