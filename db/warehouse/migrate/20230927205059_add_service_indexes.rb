class AddServiceIndexes < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_index :CustomServices, :EnrollmentID
      add_index :CustomServices, :PersonalID
      add_index :CustomServices, :data_source_id
      add_index :CustomServices, :DateProvided
      add_index :CustomServiceTypes, :hud_record_type
      add_index :CustomServiceTypes, :hud_type_provided
    end
  end
end
