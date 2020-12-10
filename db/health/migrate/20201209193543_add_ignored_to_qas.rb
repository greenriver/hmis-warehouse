class AddIgnoredToQas < ActiveRecord::Migration[5.2]
  def change
    add_column :qualifying_activities, :ignored, :boolean, default: :false
  end
end
