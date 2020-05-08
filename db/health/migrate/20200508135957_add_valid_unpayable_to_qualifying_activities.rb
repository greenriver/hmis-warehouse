class AddValidUnpayableToQualifyingActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :qualifying_activities, :valid_unpayable, :boolean, default: false, null: false
  end
end
