class AddMissingUploaderColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :eligibility_responses, :file, :string
    add_column :enrollments, :file, :string
    add_column :premium_payments, :file, :string
    add_column :transaction_acknowledgements, :file, :string
  end
end
