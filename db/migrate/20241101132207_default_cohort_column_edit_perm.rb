class DefaultCohortColumnEditPerm < ActiveRecord::Migration[7.0]
  def up
    Role.where(can_configure_cohorts: true).update_all(can_edit_cohort_columns: true)
  end
end
