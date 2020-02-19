class AutoConfirmConsentConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :auto_confirm_consent, :boolean, default: false, null: false
    GrdaWarehouse::Config.invalidate_cache
  end
end
