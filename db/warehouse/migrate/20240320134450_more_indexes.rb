class MoreIndexes < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_index :hmis_2024_exits, :importer_log_id
    end
  end
end
