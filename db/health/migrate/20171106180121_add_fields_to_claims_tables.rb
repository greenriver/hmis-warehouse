class AddFieldsToClaimsTables < ActiveRecord::Migration
  def change
    add_column :claims_amount_paid_location_month, :year_month, :string
    add_column :claims_amount_paid_location_month, :study_period, :string
    add_column :claims_claim_volume_location_month, :year_month, :string
    add_column :claims_claim_volume_location_month, :study_period, :string
  end
end
