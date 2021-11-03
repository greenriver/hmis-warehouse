class CsvColumnsAreStrings < ActiveRecord::Migration[5.2]
  def up
    change_column :hmis_csv_2022_projects, :PITCount, :string
    change_column :hmis_csv_2022_clients, :NativeHIPacific, :string
    change_column :hmis_csv_2022_clients, :NoSingleGender, :string
    change_column :hmis_csv_2022_enrollments, :HOHLeaseholder, :string
  end
end
