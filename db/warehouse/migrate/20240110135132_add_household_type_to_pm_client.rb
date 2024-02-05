class AddHouseholdTypeToPmClient < ActiveRecord::Migration[6.1]
  def change
    add_column :pm_client_projects, :household_type, :integer, comment: '2.07.4'
  end
end
