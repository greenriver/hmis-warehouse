class AddScanCardCodesTable < ActiveRecord::Migration[6.1]
  def change
    create_table(:hmis_scan_card_codes) do |t|
      t.references :client, null: false
      t.string :code, index: true, null: false # code to embed in scan card
      t.references :created_by # user that generated code
      t.references :deleted_by # user that deleted code
      t.timestamps
      t.timestamp :deleted_at
    end
  end
end
