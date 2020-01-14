class AddPatientIdToQualifyingActivities < ActiveRecord::Migration[4.2]
  def change
    add_reference :qualifying_activities, :patient
  end
end
