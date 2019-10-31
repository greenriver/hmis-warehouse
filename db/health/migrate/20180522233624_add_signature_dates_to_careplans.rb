class AddSignatureDatesToCareplans < ActiveRecord::Migration[4.2]
  def change
    add_column :careplans, :patient_signed_on, :date
    add_column :careplans, :provider_signed_on, :date
  end
end
