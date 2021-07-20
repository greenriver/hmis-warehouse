class RenameCohortColumnIndividual < ActiveRecord::Migration[5.2]
  def change
    rename_column :cohort_clients, :individual, :individual_in_most_recent_homeless_enrollment
  end
end
