class IndexDeletedAt < ActiveRecord::Migration[5.2]
  def change
    add_index :epic_patients, :deleted_at
    add_index :patient_referrals, :contributing
    add_index :patient_referrals, :deleted_at
    add_index :health_files, :deleted_at
    add_index :patients, :deleted_at
  end
end
