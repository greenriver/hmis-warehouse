class AddNewLeaseReferral < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :new_lease_referral, :string
    add_column :cohort_clients, :vulnerability_rank, :string
  end
end
