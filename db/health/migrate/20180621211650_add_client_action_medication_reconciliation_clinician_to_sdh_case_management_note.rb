class AddClientActionMedicationReconciliationClinicianToSdhCaseManagementNote < ActiveRecord::Migration
  def change
    add_column :sdh_case_management_notes, :client_action_medication_reconciliation_clinician, :string
  end
end
