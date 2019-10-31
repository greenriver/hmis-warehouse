class AddPrimaryHousingTrackSuggested < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :primary_housing_track_suggested, :string
  end
end
