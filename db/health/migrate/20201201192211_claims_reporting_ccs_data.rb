class ClaimsReportingCcsData < ActiveRecord::Migration[5.2]
  def change
    create_table "claims_reporting_ccs_lookups" do |t|
      t.string :hcpcs_start, null: false
      t.string :hcpcs_end, null: false
      t.integer :ccs_id, null: false
      t.string :ccs_label, null: false
      t.date   :effective_start, null: false
      t.date   :effective_end, null: false
      t.timestamps null: false
      t.index [:effective_start, :hcpcs_start, :hcpcs_end], unique: true, name: 'unk_code_range'
    end
  end
end
