class AddPatientConsentFlag < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :patients, :consent_revoked, :datetime, index: true
  end
end
