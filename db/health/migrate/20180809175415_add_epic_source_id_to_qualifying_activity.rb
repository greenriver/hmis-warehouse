class AddEpicSourceIdToQualifyingActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :qualifying_activities, :epic_source_id, :string, index: true
  end
end
