class AddCreateAccountFlagToTalentConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :talentlms_configs, :create_new_accounts, :boolean, default: true
  end
end
