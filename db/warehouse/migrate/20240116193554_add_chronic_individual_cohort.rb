class AddChronicIndividualCohort < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :chronic_adult_only_cohort, :boolean, default: false
  end
end
