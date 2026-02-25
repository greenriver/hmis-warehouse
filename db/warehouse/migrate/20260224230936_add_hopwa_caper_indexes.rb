class AddHopwaCaperIndexes < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_index :hopwa_caper_services, :enrollment_id
    end
  end
end
