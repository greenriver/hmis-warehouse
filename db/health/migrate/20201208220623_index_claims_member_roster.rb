class IndexClaimsMemberRoster < ActiveRecord::Migration[5.2]
  def change
    change_column_null :claims_reporting_member_rosters, :member_id, false
    add_index :claims_reporting_member_rosters, :member_id, unique: true
    add_index :claims_reporting_member_rosters, :race
    add_index :claims_reporting_member_rosters, :sex
    add_index :claims_reporting_member_rosters, :date_of_birth
    add_index :claims_reporting_member_rosters, :aco_name
  end
end
