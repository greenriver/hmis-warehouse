class IndexDatesInAnsd < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_index :ansd_enrollments, :project_type
      add_index :ansd_enrollments, :move_in_date
      add_index :ansd_enrollments, :entry_date
      add_index :ansd_enrollments, :ce_entry_date
      add_index :ansd_enrollments, :ce_referral_date
    end
  end
end
