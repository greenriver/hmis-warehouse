class AddConsentFormsVisibleConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :consent_visible_to_all, :boolean, default: false
  end
end
