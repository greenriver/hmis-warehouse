class CreateSignatureRequests < ActiveRecord::Migration
  def change
    create_table :signature_requests do |t|
      t.string :type, null: false, index: true
      t.references :patient, null: false, index: true
      t.references :careplan, null: false, index: true
      t.string :to_email, null: false
      t.string :to_name, null: false
      t.string :requestor_email, null: false
      t.string :requestor_name, null: false
      t.datetime :expires_at, null: false
      t.datetime :sent_at
      t.datetime :completed_at
      t.timestamps
      t.datetime :deleted_at, index: true
    end
  end
end
