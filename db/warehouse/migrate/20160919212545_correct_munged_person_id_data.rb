# tried to do this using reset_column_information in one migration, but that hung indefinitely
class CorrectMungedPersonIdData < ActiveRecord::Migration
  MUNGERS = [
    "Boston Department of Neighborhood Development",
    "Boston Public Health Commission",
    "DND Warehouse"
  ]
  def change
    GrdaWarehouse::DataSource.where( name: MUNGERS ).update_all munged_personal_id: true
  end
end
