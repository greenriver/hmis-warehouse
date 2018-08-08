class AddDuplicateToQualifyingActivity < ActiveRecord::Migration
  def change
    add_column :qualifying_activities, :duplicate_id, :integer
  end
end
