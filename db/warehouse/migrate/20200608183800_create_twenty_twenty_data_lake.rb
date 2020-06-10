class CreateTwentyTwentyDataLake < ActiveRecord::Migration[5.2]
  def up
    HmisCsvImporter::TwentyTwenty.models_by_hud_filename.each do |_, klass|
      klass.hmis_table_create!(version: '2020', constraints: false)
      klass.hmis_table_create_indices!(version: '2020')
    end
  end

  def down
    HmisCsvImporter::TwentyTwenty.models_by_hud_filename.each do |_, klass|
      drop_table klass.table_name
    end
  end
end
