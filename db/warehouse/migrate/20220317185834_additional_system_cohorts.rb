class AdditionalSystemCohorts < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :youth_no_child_cohort, :boolean, default: false, null: false
    add_column :configs, :youth_and_child_cohort, :boolean, default: false, null: false
  end
end
