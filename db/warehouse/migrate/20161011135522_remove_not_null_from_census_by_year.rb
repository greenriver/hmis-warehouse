class RemoveNotNullFromCensusByYear < ActiveRecord::Migration[4.2]
  def change
    change_column :censuses_averaged_by_year, :data_source_id, :integer, null: true
    change_column :censuses_averaged_by_year, :OrganizationID, :string, null: true
    change_column :censuses_averaged_by_year, :ProjectID, :string, null: true
  end
end
