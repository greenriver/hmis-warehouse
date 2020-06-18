class AddIndicesToDataLakes < ActiveRecord::Migration[5.2]
  def up
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each_value do |klass|
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      if klass.column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
      if klass.column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
        add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
    end
    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each_value do |klass|
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      if klass.column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
      if klass.column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
        add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}"
      end
    end
  end

  def down
    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each_value do |klass|
      index_name = klass.connection.indexes(klass.table_name).detect{|i| i.columns == [klass.hud_key.to_s, 'data_source_id']}.name
      puts "removing: #{index_name} from #{klass.table_name}"
      remove_index klass.table_name, column: [klass.hud_key, :data_source_id], name: index_name
      if klass.column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        index_name = klass.connection.indexes(klass.table_name).detect{|i| i.columns == ['EnrollmentID', 'data_source_id']}.name
        puts "removing: #{index_name} from #{klass.table_name}"
        remove_index klass.table_name, column: [:EnrollmentID, :data_source_id], name: index_name
      end
      if klass.column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
        index_name = klass.connection.indexes(klass.table_name).detect{|i| i.columns == ['ProjectID', 'data_source_id']}.name
        puts "removing: #{index_name} from #{klass.table_name}"
        remove_index klass.table_name, column: [:ProjectID, :data_source_id], name: index_name
      end
    end

    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each_value do |klass|
      index_name = klass.connection.indexes(klass.table_name).detect{|i| i.columns == [klass.hud_key.to_s, 'data_source_id']}.name
      puts "removing: #{index_name} from #{klass.table_name}"
      remove_index klass.table_name, column: [klass.hud_key, :data_source_id], name: index_name
      if klass.column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        index_name = klass.connection.indexes(klass.table_name).detect{|i| i.columns == ['EnrollmentID', 'data_source_id']}.name
        puts "removing: #{index_name} from #{klass.table_name}"
        remove_index klass.table_name, column: [:EnrollmentID, :data_source_id], name: index_name
      end
      if klass.column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
        index_name = klass.connection.indexes(klass.table_name).detect{|i| i.columns == ['ProjectID', 'data_source_id']}.name
        puts "removing: #{index_name} from #{klass.table_name}"
        remove_index klass.table_name, column: [:ProjectID, :data_source_id], name: index_name
      end
    end
  end
end
