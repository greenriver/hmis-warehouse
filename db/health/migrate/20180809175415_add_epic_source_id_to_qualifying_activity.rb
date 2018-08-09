class AddEpicSourceIdToQualifyingActivity < ActiveRecord::Migration
  def change
    add_column :qualifying_activities, :epic_source_id, :string, index: true
  end
end
