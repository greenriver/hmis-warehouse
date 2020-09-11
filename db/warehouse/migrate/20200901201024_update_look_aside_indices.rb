class UpdateLookAsideIndices < ActiveRecord::Migration[5.2]
  def up

    [HmisCsvTwentyTwenty::Aggregated::Enrollment].each do |klass|
      remove_index klass.table_name, [klass.hud_key, :data_source_id] if index_exists?(klass.table_name, [klass.hud_key, :data_source_id])
      add_index klass.table_name, [klass.hud_key, :PersonalID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}", unique: true
    end

    [HmisCsvTwentyTwenty::Aggregated::Exit].each do |klass|
      remove_index klass.table_name, [klass.hud_key, :data_source_id] if index_exists?(klass.table_name, [klass.hud_key, :data_source_id])
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}", unique: true
    end
  end

end
