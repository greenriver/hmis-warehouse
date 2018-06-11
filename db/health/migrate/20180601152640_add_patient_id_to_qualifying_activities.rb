class AddPatientIdToQualifyingActivities < ActiveRecord::Migration
  def change
    add_reference :qualifying_activities, :patient
  end
end
