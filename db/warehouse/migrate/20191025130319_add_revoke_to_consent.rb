class AddRevokeToConsent < ActiveRecord::Migration
  def change
    add_column :files, :consent_revoked_at, :datetime, index: true
    remove_column :files, :coc_code, :string
    add_column :files, :coc_codes, :jsonb, index: true, default: []
    add_column :Client, :consented_coc_codes, :jsonb, index: true, default: []
  end
end
