class AddPcPandPatientRequestedSignaturesToPctp < ActiveRecord::Migration
  def change
    add_column :member_status_report_patients, :cp_contact_face, :string
    add_column :member_status_reports, :error, :string
    add_column :careplans, :patient_signature_requested_at, :datetime
    add_column :careplans, :provider_signature_requested_at, :datetime
  end
end
