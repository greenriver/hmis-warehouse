class CreateClientRoiAuthorizations < ActiveRecord::Migration[7.0]
  def change
    create_table :client_roi_authorizations do |t|
      t.references :destination_client, null: false, index: { unique: true }
      t.string :status, null: false
      t.string :coc_codes, array: true
      t.date :starts_at
      t.date :expires_at
    end
  end
end
