class RemoveIncorrectImportOverrides < ActiveRecord::Migration[6.1]
  def up
    return unless RailsDrivers.loaded.include?(:hmis_csv_importer)

    HmisCsvImporter::ImportOverride.where(
      file_name: 'Inventory.csv',
      replaces_column: ['CoCCode', 'InventoryStartDate', 'InventoryEndDate'],
      replacement_value: [nil, ''],
    ).delete_all
    HmisCsvImporter::ImportOverride.where(
      file_name: 'ProjectCoC.csv',
      replaces_column: ['CoCCode', 'Zip', 'Geocode', 'GeographyType'],
      replacement_value: [nil, '']
    ).delete_all
    HmisCsvImporter::ImportOverride.where(
      file_name: 'Project.csv',
      replaces_column: ['OperatingStartDate', 'OperatingEndDate', 'ProjectType'],
      replacement_value: [nil, '']
    ).delete_all
  end
end
