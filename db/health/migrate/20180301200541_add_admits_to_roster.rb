class AddAdmitsToRoster < ActiveRecord::Migration
  def change
    add_column :claims_roster, :baseline_admits, :integer
    add_column :claims_roster, :implementation_admits, :integer
  end
end
