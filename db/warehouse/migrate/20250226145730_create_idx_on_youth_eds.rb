class CreateIdxOnYouthEds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    safety_assured do
      add_index 'YouthEducationStatus', ['EnrollmentID', 'data_source_id', 'PersonalID'], name: 'idx_youth_eds_hud_keys'
    end
  end

  def down
    drop_index('idx_youth_eds_hud_keys')
  end
end
