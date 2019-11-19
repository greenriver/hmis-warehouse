class AddConsentFormsVisibleConfig < ActiveRecord::Migration
  def change
    add_column :configs, :consent_visible_to_all, :boolean, default: false
  end
end
