class ChangeLastPermanentCityToString < ActiveRecord::Migration
  def change
    table = GrdaWarehouse::Hud::Enrollment.table_name
    change_column table, :LastPermanentCity, :string, limit: 50
  end
end
