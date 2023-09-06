class RemoveOccurrencePointCol < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      remove_column :CustomDataElementDefinitions, :at_occurrence, :boolean
    }
  end
end
