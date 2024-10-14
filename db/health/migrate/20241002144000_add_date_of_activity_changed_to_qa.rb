class AddDateOfActivityChangedToQa < ActiveRecord::Migration[7.0]
  def change
    add_column :qualifying_activities, :date_of_activity_changed, :boolean, default: false
  end
end
