class AddHouseholdIdToEnrollmentCoC < ActiveRecord::Migration[4.2]
  def change
    table = GrdaWarehouse::Hud::EnrollmentCoc.table_name
    add_column table, 'HouseholdID', :string, limit: 32
  end
end
