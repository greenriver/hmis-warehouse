class AdjustCohortClientColumns < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :first_date_homeless, :datetime
    add_column :cohort_clients, :last_date_approached, :datetime
    add_column :cohort_clients, :chronic, :boolean, default: false
    add_column :cohort_clients, :dnd_rank, :string
    add_column :cohort_clients, :veteran, :boolean, default: false
    remove_column :cohort_clients, :housing_track, :string
    add_column :cohort_clients, :housing_track_suggested, :string
    add_column :cohort_clients, :housing_track_enrolled, :string
  end
end
