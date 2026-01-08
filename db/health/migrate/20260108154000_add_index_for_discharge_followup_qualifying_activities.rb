# frozen_string_literal: true

class AddIndexForDischargeFollowupQualifyingActivities < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<~SQL
        CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_qa_dfu_patient_date
        ON qualifying_activities (patient_id, date_of_activity)
        WHERE deleted_at IS NULL AND activity = 'discharge_follow_up';
      SQL
    end
  end

  def down
    safety_assured do
      execute 'DROP INDEX CONCURRENTLY IF EXISTS idx_qa_dfu_patient_date'
    end
  end
end
