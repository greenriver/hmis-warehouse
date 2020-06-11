class AddFieldsToDataLake < ActiveRecord::Migration[5.2]
  def change
    HmisCsvImporter::TwentyTwenty.models_by_hud_filename.each do |_, klass|
      add_column klass.table_name, :data_source_id, :integer, null: false, index: true
      add_column klass.table_name, :imported_at, :datetime, null: false
      add_column klass.table_name, :processed_as, :string
      add_column klass.table_name, :loader_id, :integer, null: false, index: true
    end
  end
end
