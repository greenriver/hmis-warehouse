class AddConsentFormIdToClients < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :consent_form_id, :integer
  end
end
