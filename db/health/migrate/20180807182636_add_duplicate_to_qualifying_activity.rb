class AddDuplicateToQualifyingActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :qualifying_activities, :duplicate_id, :integer
  end
end
