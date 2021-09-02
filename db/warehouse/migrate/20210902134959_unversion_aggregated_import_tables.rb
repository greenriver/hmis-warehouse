class UnversionAggregatedImportTables < ActiveRecord::Migration[5.2]
  def up
    change_table :hmis_2020_aggregated_enrollments do |t|
      t.integer :MentalHealthDisorderFam
      t.integer :AlcoholDrugUseDisorderFam
      t.integer :ClientLeaseholder
      t.integer :HOHLeasesholder
      t.integer :IncarceratedAdult
      t.integer :PrisonDischarge
      t.integer :CurrentPregnant
      t.integer :CoCPrioritized
      t.integer :TargetScreenReqd
    end

    klasses.each do |klass|
      klass.hmis_table_create!(version: '2022', constraints: false)
      klass.hmis_table_create_indices!(version: '2022')
    end

    klasses.each do |klass|
      add_column klass.table_name, :data_source_id, :integer, null: false, index: true
      add_column klass.table_name, :importer_log_id, :integer, index: true, null: false
      add_column klass.table_name, :pre_processed_at, :datetime, null: false
      add_column klass.table_name, :source_hash, :string
      add_column klass.table_name, :source_id, :integer, null: false
      add_column klass.table_name, :source_type, :string, null: false

      add_column klass.table_name, :dirty_at, :timestamp, index: true
      add_column klass.table_name, :clean_at, :timestamp, index: true

      add_index klass.table_name, [:source_type, :source_id], name: klass.table_name + '-' + SecureRandom.alphanumeric(4)
    end

    [HmisCsvImporter::Aggregated::Enrollment].each do |klass|
      add_index klass.table_name, [klass.hud_key, :PersonalID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}", unique: true
    end

    [HmisCsvImporter::Aggregated::Exit].each do |klass|
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}", unique: true
    end

    add_index :hmis_aggregated_enrollments, [:PersonalID, :ProjectID, :data_source_id], name: :hmis_agg_enrollments_p_id_p_id_ds_id
  end

  def down
    klasses.each do |klass|
      drop_table klass.table_name
    end

    change_table :hmis_2020_aggregated_enrollments do |t|
      t.remove :MentalHealthDisorderFam
      t.remove :AlcoholDrugUseDisorderFam
      t.remove :ClientLeaseholder
      t.remove :HOHLeasesholder
      t.remove :IncarceratedAdult
      t.remove :PrisonDischarge
      t.remove :CurrentPregnant
      t.remove :CoCPrioritized
      t.remove :TargetScreenReqd
    end
  end

  def klasses
    [HmisCsvImporter::Aggregated::Enrollment, HmisCsvImporter::Aggregated::Exit]
  end
end
