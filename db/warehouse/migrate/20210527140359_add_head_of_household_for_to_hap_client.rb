class AddHeadOfHouseholdForToHapClient < ActiveRecord::Migration[5.2]
  def change
    add_column :hap_report_clients, :head_of_household_for, :string, array: true
  end
end
