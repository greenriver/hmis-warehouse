class AddNameAndDefaultToTalentlmsConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :talentlms_configs, :configuration_name, :varchar
    add_column :talentlms_configs, :default, :boolean, null: false, default: false
  end
end
