class AdditionalSystemCohortConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :veteran_cohort, :boolean, default: false, null: false
    add_column :configs, :youth_cohort, :boolean, default: false, null: false
    add_column :configs, :chronic_cohort, :boolean, default: false, null: false
    add_column :configs, :adult_and_child_cohort, :boolean, default: false, null: false
    add_column :configs, :adult_only_cohort, :boolean, default: false, null: false
  end
end
