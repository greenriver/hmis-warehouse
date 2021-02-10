class AddMissingUniqueKeys < ActiveRecord::Migration[5.2]
  def change
    change_column_null :claims_reporting_member_rosters, :member_id, false
    add_index :claims_reporting_member_rosters, ['member_id'], unique: true, name: 'unk_cr_member_roster'

    change_column_null :claims_reporting_medical_claims, :member_id, false
    change_column_null :claims_reporting_medical_claims, :claim_number, false
    change_column_null :claims_reporting_medical_claims, :line_number, false
    add_index :claims_reporting_medical_claims, ['member_id', 'claim_number', 'line_number'], unique: true, name: 'unk_cr_medical_claim'

    change_column_null :claims_reporting_rx_claims, :member_id, false
    change_column_null :claims_reporting_rx_claims, :claim_number, false
    change_column_null :claims_reporting_rx_claims, :line_number, false
    add_index :claims_reporting_rx_claims, ['member_id', 'claim_number', 'line_number'], unique: true, name: 'unk_cr_rx_claims'

    change_column_null :claims_reporting_member_enrollment_rosters, :member_id, false
    change_column_null :claims_reporting_member_enrollment_rosters, :span_start_date, false
    add_index :claims_reporting_member_enrollment_rosters, ['member_id', 'span_start_date'], unique: true, name: 'unk_cr_member_enrollment_roster'
  end
end
