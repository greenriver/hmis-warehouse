class AddPrimaryHousingTrackSuggested < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :primary_housing_track_suggested, :string
  end
end
