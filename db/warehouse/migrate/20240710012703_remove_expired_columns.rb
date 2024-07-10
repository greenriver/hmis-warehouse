class RemoveExpiredColumns < ActiveRecord::Migration[7.0]
  def tables
    (
      HmisCsvTwentyTwenty.expiring_loader_classes +
      HmisCsvTwentyTwenty.expiring_importer_classes +
      HmisCsvTwentyTwentyTwo.expiring_loader_classes +
      HmisCsvTwentyTwentyTwo.expiring_importer_classes +
      HmisCsvTwentyTwentyFour.expiring_loader_classes +
      HmisCsvTwentyTwentyFour.expiring_importer_classes
    ).map(&:table_name).sort
  end

  def change
    tables.each do |table|
      remove_column(table, :expired, :boolean) if column_exists?(table, :expired)
    end
  end
end
