class AddColumnsToContactTracingStaff < ActiveRecord::Migration[5.2]
  def change
    change_table :tracing_staffs do |t|
      t.date :dob
      t.string :estimated_age
      t.integer :gender
      t.string :address
      t.string :phone_number
      t.jsonb :symptoms
      t.string :other_symptoms
    end
  end
end
