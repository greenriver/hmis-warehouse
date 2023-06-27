class AddDatasourceIdToReferralPosting < ActiveRecord::Migration[6.1]
  def change
    HmisExternalApis::AcHmis::ReferralPosting.delete_all
    safety_assured {
      add_column :hmis_external_referral_postings, :data_source_id, :integer, null: false
      rename_column :hmis_external_referral_postings, :household_id, :HouseholdID
    }
  end
end
