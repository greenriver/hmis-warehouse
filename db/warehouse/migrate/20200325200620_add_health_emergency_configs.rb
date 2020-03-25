class AddHealthEmergencyConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :health_emergency, :string
  end
end
