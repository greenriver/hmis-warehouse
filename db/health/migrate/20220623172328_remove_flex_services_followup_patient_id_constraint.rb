class RemoveFlexServicesFollowupPatientIdConstraint < ActiveRecord::Migration[6.1]
  def change
    change_column_null :health_flexible_service_follow_ups, :patient_id, true
  end
end
