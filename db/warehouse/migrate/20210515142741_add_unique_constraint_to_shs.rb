class AddUniqueConstraintToShs < ActiveRecord::Migration[5.2]
  def change
    add_index :service_history_services, [:date, :service_history_enrollment_id], unique: true, name: 'shs_unique_date_she_id'
  end
end
