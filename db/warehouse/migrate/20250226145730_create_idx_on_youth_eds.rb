class CreateIdxOnYouthEds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index 'YouthEducationStatus', ['EnrollmentID', 'data_source_id', 'PersonalID'], name: 'idx_youth_eds_hud_keys', algorithm: :concurrently
  end

  def down
    drop_index('idx_youth_eds_hud_keys')
  end
end
