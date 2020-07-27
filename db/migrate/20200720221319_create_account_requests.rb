class CreateAccountRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :account_requests do |t|
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :status, null: false
      t.text :details
      t.datetime :accepted_at
      t.integer :accepted_by
      t.string :rejection_reason
      t.datetime :rejected_at
      t.integer :rejected_by
      t.references :user # used once the user account is created
      t.timestamps
    end
  end
end
