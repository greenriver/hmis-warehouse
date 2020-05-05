class AddAcoChangesToEligibilityResponses < ActiveRecord::Migration[5.2]
  def change
    add_column :eligibility_responses, :patient_aco_changes, :json
  end
end
