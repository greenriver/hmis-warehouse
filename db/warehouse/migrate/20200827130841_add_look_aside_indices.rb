class AddLookAsideIndices < ActiveRecord::Migration[5.2]
  def up
    klasses.each do |klass|
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{SecureRandom.alphanumeric(4)}", unique: true
    end
  end

  def klasses
    [HmisCsvTwentyTwenty::Aggregated::Enrollment, HmisCsvTwentyTwenty::Aggregated::Exit]
  end
end
