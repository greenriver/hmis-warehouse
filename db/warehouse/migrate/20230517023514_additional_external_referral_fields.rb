class AdditionalExternalReferralFields < ActiveRecord::Migration[6.1]
  def change
    referral_requests = :hmis_external_referral_requests
    postings = :hmis_external_referral_postings
    referrals = :hmis_external_referrals

    change_column_null referral_requests, :identifier, true

    change_column_null referrals, :identifier, true
    add_reference referrals, :enrollment


    add_column referrals, :referral_notes, :text
    add_column referrals, :chronic, :boolean
    add_column referrals, :score, :integer
    add_column referrals, :needs_wheelchair_accessible_unit, :boolean

    change_column_null postings, :identifier, true
    add_column postings, :household_id, :string
    add_column postings, :resource_coordinator_notes, :text
    add_column postings, :status_updated_at, :datetime, null: false
    add_reference postings, :status_updated_by, index: {name: "idx_#{postings}_user_1"}
    add_column postings, :status_note, :text
    add_column postings, :status_note_updated_at, :text
    add_reference postings, :status_note_updated_by, index: {name: "idx_#{postings}_user_2"}
    add_column postings, :denial_reason, :integer
    add_column postings, :denial_note, :text
  end
end
