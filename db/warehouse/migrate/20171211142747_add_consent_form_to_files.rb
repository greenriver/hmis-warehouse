class AddConsentFormToFiles < ActiveRecord::Migration
  def change
    add_column :files, :consent_form_signed_on, :date
    add_column :files, :consent_form_confirmed, :boolean
  end
end
