class AddPitCountToNewStagingTables < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_csv_2022_projects, :PITCount, :integer unless column_exists? :hmis_csv_2022_projects, :PITCount
    add_column :hmis_csv_2022_projects, :PITCount, :integer unless column_exists? :hmis_csv_2022_projects, :PITCount
  end
end
