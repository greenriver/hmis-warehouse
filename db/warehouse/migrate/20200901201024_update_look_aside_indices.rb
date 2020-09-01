class UpdateLookAsideIndices < ActiveRecord::Migration[5.2]
  def up

    klasses.each do |klass|
      remove_index klass.table_name, [klass.hud_key, :data_source_id]
      add_index klass.table_name, [klass.hud_key, :PersonalID, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}", unique: true
    end
  end

  def klasses
    [HmisCsvTwentyTwenty::Aggregated::Enrollment]
  end
end
