class AddConsentFormSignedOnToClient < ActiveRecord::Migration[4.2]
  def up
    add_column :Client, :consent_form_signed_on, :date
  end

  def down
    remove_column :Client, :consent_form_signed_on
  end
end
