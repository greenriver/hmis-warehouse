class AddInitialCohortColumnOptions < ActiveRecord::Migration
  def up
  	GrdaWarehouse::CohortColumnOption.add_initial_cohort_column_options
  end

  def down
  	GrdaWarehouse::CohortColumnOption.delete_all
  end

end
