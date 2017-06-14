class AddPatientConsentFlag < ActiveRecord::Migration
  def change
    add_column :patients, :consent_revoked, :datetime, index: true
  end
end
