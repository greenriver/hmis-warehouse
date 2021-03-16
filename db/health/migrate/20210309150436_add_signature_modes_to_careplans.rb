class AddSignatureModesToCareplans < ActiveRecord::Migration[5.2]
  def change
    add_column :careplans, :patient_signature_mode, :string
    add_column :careplans, :provider_signature_mode, :string
  end
end
