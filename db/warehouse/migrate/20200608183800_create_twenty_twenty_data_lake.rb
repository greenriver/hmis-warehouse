class CreateTwentyTwentyDataLake < ActiveRecord::Migration[5.2]
  def up
    HmisCsvTwentyTwenty::Importer::Base.importable_files.each do |_, klass|
      klass.hmis_table_create!(version: '2020', constraints: false)
      klass.hmis_table_create_indices!(version: '2020')
    end
    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each do |_, klass|
      klass.hmis_table_create!(version: '2020', constraints: false, types: false)
      klass.hmis_table_create_indices!(version: '2020')
    end
  end

  def down
    HmisCsvTwentyTwenty::Importer::Base.importable_files.each do |_, klass|
      drop_table klass.table_name
    end
    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each do |_, klass|
      drop_table klass.table_name
    end
  end
end
