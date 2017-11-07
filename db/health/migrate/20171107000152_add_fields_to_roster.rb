class AddFieldsToRoster < ActiveRecord::Migration
  def change
    add_column :claims_roster, :member_months_baseline, :integer
    add_column :claims_roster, :member_months_implementation, :integer
    add_column :claims_roster, :cost_rank_ty, :integer
    add_column :claims_roster, :average_ed_visits_baseline, :float
    add_column :claims_roster, :average_ed_visits_implementation, :float
    add_column :claims_roster, :average_ip_admits_baseline, :float
    add_column :claims_roster, :average_ip_admits_implementation, :float
    add_column :claims_roster, :average_days_to_readmit_baseline, :float
    add_column :claims_roster, :average_days_to_implementation, :float
    add_column :claims_roster, :case_manager, :string
    add_column :claims_roster, :housing_status, :string
  end
end
