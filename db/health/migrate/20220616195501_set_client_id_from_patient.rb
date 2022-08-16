class SetClientIdFromPatient < ActiveRecord::Migration[6.1]
  def up
    HealthFlexibleService::Vpr.preload(:patient).find_each do |vpr|
      vpr.update(
        client_id: vpr.patient.client_id,
        medicaid_id: vpr.patient.medicaid_id,
        aco_id: vpr.patient.aco&.id,
      )
    end
  end
end
