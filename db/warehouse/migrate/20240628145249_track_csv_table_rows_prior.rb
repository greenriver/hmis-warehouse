class TrackCsvTableRowsPrior < ActiveRecord::Migration[7.0]
  def tables
    (
      HmisCsvTwentyTwenty.expiring_loader_classes +
      HmisCsvTwentyTwenty.expiring_importer_classes +
      HmisCsvTwentyTwentyTwo.expiring_loader_classes +
      HmisCsvTwentyTwentyTwo.expiring_importer_classes
    ).map(&:table_name).sort
  end

  def change
    tables.each do |table|
      add_column table, :expired, :boolean
    end
  end
end
