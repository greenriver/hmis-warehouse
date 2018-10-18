class CreateSignableDocuments < ActiveRecord::Migration
  def change
    create_table :signable_documents do |t|
      t.integer  "signable_id",   null: false
      t.string   "signable_type", null: false
      t.boolean  :primary, null: false, default: true
      t.integer  :user_id, null: false

      t.jsonb    "hs_initial_request"
      t.jsonb    "hs_initial_response"
      t.datetime "hs_initial_response_at"
      t.jsonb    "hs_last_response"
      t.datetime "hs_last_response_at"
      t.string :hs_subject, null: false, default: 'Signature Request'
      t.string :hs_title, null: false, default: 'Signature Request'
      t.text :hs_message, nul: false, default: "You've been asked to sign a document."

      t.jsonb "signers", default: '[]', null: false
      t.jsonb "signed_by", default: '[]', null: false

      t.timestamps

      t.index ["signable_id", "signable_type"]
    end
  end
end
