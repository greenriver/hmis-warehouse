class AddScanCardCodesTable < ActiveRecord::Migration[6.1]
  def change
    create_table(:hmis_scan_card_codes) do |t|
      t.references :client, null: false
      t.string :value, index: { unique: true }, null: false, comment: 'code to embed in scan card'
      t.references :created_by, comment: 'user that generated code'
      t.references :deleted_by, comment: 'user that deleted code'
      t.timestamps
      t.timestamp :deleted_at
      t.timestamp :expires_at, comment: 'when scan card should expire'
    end
  end
end
