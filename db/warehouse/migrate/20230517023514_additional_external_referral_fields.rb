class AdditionalExternalReferralFields < ActiveRecord::Migration[6.1]
  def change
    postings = :hmis_external_referral_postings
    referrals = :hmis_external_referrals

    change_column_null referrals, :identifier, true
    add_column referrals, :score, :integer
    add_column referrals, :needs_wheelchair_accessible_unit, :boolean
    add_column referrals, :referral_notes, :text
    add_column referrals, :chronic, :boolean

    change_column_null postings, :identifier, true
    add_column postings, :resource_coordinator_notes, :text
    add_column postings, :household_id, :string
  end
end

=begin
   create_table :hmis_external_referral_postings do |t|
      t.timestamps
      t.string :identifier, null: false, index: { unique: true, name: 'uidx_hmis_external_referral_posting_identifier' }
      t.integer :status, null: false
      t.references :referral, null: false, foreign_key: { to_table: :hmis_external_referrals }, index: false
      t.references :project, null: false, foreign_key: { to_table: 'Project' }
      # t.references :unit_type, null: false, foreign_key: { to_table: :hmis_unit_types }
      t.references :referral_request, null: true, foreign_key: { to_table: :hmis_external_referral_requests },
                                      index: { name: 'idx_hmis_external_referral_postings_on_request_id' }
      t.index [:referral_id, :referral_request_id], unique: true, name: 'uidx_hmis_external_referral_postings_1'
    end
      add_reference :hmis_external_referral_postings, :unit_type, null: false, foreign_key: { to_table: :hmis_unit_types
=end
