class Importer2022v1pSpecItems < ActiveRecord::Migration[5.2]
  def up
    add_column :hmis_csv_2022_clients, :NativeHIPacific, :integer unless column_exists? :hmis_csv_2022_clients, :NativeHIPacific
    add_column :hmis_csv_2022_clients, :NoSingleGender, :integer unless column_exists? :hmis_csv_2022_clients, :NoSingleGender
    add_column :hmis_csv_2022_enrollments, :HOHLeaseholder, :integer unless column_exists? :hmis_csv_2022_enrollments, :HOHLeaseholder
    rename_column :hmis_csv_2022_events, :LocationCrisisorPHHousing, :LocationCrisisOrPHHousing unless column_exists? :hmis_csv_2022_events, :LocationCrisisOrPHHousing
    rename_column :hmis_csv_2022_health_and_dvs, :SupportfromOthers, :SupportFromOthers unless column_exists? :hmis_csv_2022_health_and_dvs, :SupportFromOthers

    add_column :hmis_2022_clients, :NativeHIPacific, :integer unless column_exists? :hmis_2022_clients, :NativeHIPacific
    add_column :hmis_2022_clients, :NoSingleGender, :integer unless column_exists? :hmis_2022_clients, :NoSingleGender
    add_column :hmis_2022_enrollments, :HOHLeaseholder, :integer unless column_exists? :hmis_2022_enrollments, :HOHLeaseholder
    rename_column :hmis_2022_events, :LocationCrisisorPHHousing, :LocationCrisisOrPHHousing unless column_exists? :hmis_2022_events, :LocationCrisisOrPHHousing
    rename_column :hmis_2022_health_and_dvs, :SupportfromOthers, :SupportFromOthers unless column_exists? :hmis_2022_health_and_dvs, :SupportFromOthers

    add_column :hmis_aggregated_enrollments, :HOHLeaseholder, :integer unless column_exists? :hmis_aggregated_enrollments, :HOHLeaseholder
  end

  def down
    remove_column :hmis_csv_2022_clients, :NativeHIPacific, :integer
    remove_column :hmis_csv_2022_clients, :NoSingleGender, :integer
    remove_column :hmis_csv_2022_enrollments, :HOHLeaseholder, :integer
    rename_column :hmis_csv_2022_events, :LocationCrisisOrPHHousing, :LocationCrisisorPHHousing
    rename_column :hmis_csv_2022_health_and_dvs, :SupportFromOthers, :SupportfromOthers

    remove_column :hmis_2022_clients, :NativeHIPacific, :integer
    remove_column :hmis_2022_clients, :NoSingleGender, :integer
    remove_column :hmis_2022_enrollments, :HOHLeaseholder, :integer
    rename_column :hmis_2022_events, :LocationCrisisOrPHHousing, :LocationCrisisorPHHousing
    rename_column :hmis_2022_health_and_dvs, :SupportFromOthers, :SupportfromOthers

    remove_column :hmis_aggregated_enrollments, :HOHLeaseholder, :integer
  end
end
