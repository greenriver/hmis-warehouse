class AddMonthsToExpirationToTalentlmsConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :talentlms_configs, :months_to_expiration, :integer
  end
end
