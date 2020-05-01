class CreateTestUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :health_emergency_test_batches do |t|
      t.references :user
      t.integer :uploaded_count
      t.integer :matched_count
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
      t.string :import_errors
      t.string :file
      t.string :name
      t.string :size
      t.string :content_type
      t.binary :content
    end

    create_table :health_emergency_uploaded_tests do |t|
      t.references :batch
      t.integer :client_id
      t.integer :test_id
      t.string :first_name
      t.string :last_name
      t.date :dob
      t.string :gender
      t.string :ssn
      t.date :tested_on
      t.string :test_location
      t.string :test_result
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end
  end
end
