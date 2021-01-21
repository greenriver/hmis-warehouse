class AcknowledgeSyntheticCloses < ActiveRecord::Migration[5.2]
  def change
    Health::PatientReferral.where(
      change_description: 'Close open enrollment',
      removal_acknowledged: false,
    ).update_all(
      removal_acknowledged: true,
    )
  end
end
