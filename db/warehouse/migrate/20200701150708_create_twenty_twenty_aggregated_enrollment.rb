class CreateTwentyTwentyAggregatedEnrollment < ActiveRecord::Migration[5.2]
  def up
    klasses.each do |klass|
      klass.hmis_table_create!(version: '2020', constraints: false)
      klass.hmis_table_create_indices!(version: '2020')
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
      # add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      # column_names = klass.column_names
      # if column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
      #   add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      # end
      # if column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
      #   add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      # end
    end
  end

  def down
    klasses.each do |klass|
      drop_table klass.table_name
    end
  end

  def klasses
    [HmisCsvTwentyTwenty::Aggregated::Enrollment, HmisCsvTwentyTwenty::Aggregated::Exit]
  end
end
