class FixReferralPostingStatusNoteUpdatedAt < ActiveRecord::Migration[6.1]
  def change
    # should be okay to just drop this since we aren't in production yet
    safety_assured do
      remove_column :hmis_external_referral_postings, :status_note_updated_at, :string
      add_column :hmis_external_referral_postings, :status_note_updated_at, :datetime
    end
  end
end
