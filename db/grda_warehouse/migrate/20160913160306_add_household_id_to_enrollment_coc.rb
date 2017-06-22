class AddHouseholdIdToEnrollmentCoc < ActiveRecord::Migration
  def change
    table = GrdaWarehouse::Hud::EnrollmentCoc.table_name
    add_column table, 'HouseholdID', :string, limit: 32
  end
end
