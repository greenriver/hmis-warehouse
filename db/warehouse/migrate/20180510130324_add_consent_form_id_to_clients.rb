class AddConsentFormIdToClients < ActiveRecord::Migration
  def change
    add_column :Client, :consent_form_id, :integer
  end
end
