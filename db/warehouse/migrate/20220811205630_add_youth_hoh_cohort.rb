class AddYouthHohCohort < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :youth_hoh_cohort, :boolean, default: false, null: false
    add_column :configs, :youth_hoh_cohort_project_group_id, :integer, null: true
  end
end
