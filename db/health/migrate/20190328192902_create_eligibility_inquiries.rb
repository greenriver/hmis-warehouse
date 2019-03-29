class CreateEligibilityInquiries < ActiveRecord::Migration
  def change
    create_table :eligibility_inquiries do |t|
      t.date :service_date, null: false
      t.string :inquiry
      t.string :result

      t.integer :isa_control_number, null: false
      t.integer :group_control_number, null: false
      t.integer :transaction_control_number, null: false

      t.timestamps
    end
  end
end
