class AddSignatureDatesToCareplans < ActiveRecord::Migration
  def change
    add_column :careplans, :patient_signed_on, :date
    add_column :careplans, :provider_signed_on, :date
  end
end
