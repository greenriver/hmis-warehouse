class CreateEpicPatients < ActiveRecord::Migration
  def change
    create_table :epic_patients, force: :cascade do |t|
      t.string   :id_in_source,                             null: false
      t.string   :first_name
      t.string   :middle_name
      t.string   :last_name
      t.text     :aliases
      t.date     :birthdate
      t.text     :allergy_list
      t.string   :primary_care_physician
      t.string   :transgender
      t.string   :race
      t.string   :ethnicity
      t.string   :veteran_status
      t.string   :ssn
      t.datetime :created_at,                               null: false
      t.datetime :updated_at,                               null: false
      t.string   :gender
      t.datetime :consent_revoked
      t.string   :medicaid_id
      t.string   :housing_status
      t.datetime :housing_status_timestamp
      t.boolean  :pilot,                    default: false, null: false
      t.integer  :data_source_id,           default: Health::DataSource.first.id,     null: false
      t.datetime :deleted_at
    end
  end
end
