class ChangeLastPermanentCityToString < ActiveRecord::Migration[4.2]
  def change
    table = GrdaWarehouse::Hud::Enrollment.table_name
    change_column table, :LastPermanentCity, :string, limit: 50
  end
end
