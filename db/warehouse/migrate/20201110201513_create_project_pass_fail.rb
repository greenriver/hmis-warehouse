class CreateProjectPassFail < ActiveRecord::Migration[5.2]
  def change
    create_table :project_pass_fails do |t|
      t.references :user, index: true
      t.jsonb :options, default: {}
      t.datetime :started_at
      t.datetime :completed_at
      t.float :utilization_rate
      t.float :universal_data_element_rate
      t.float :average_timeliness
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end

    create_table :project_pass_fails_projects do |t|
      t.references :project_pass_fail, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, index: true
      t.float :available_beds
      t.float :utilization_rate
      t.float :universal_data_element_rate
      t.float :average_timeliness
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end

    create_table :project_pass_fails_clients do |t|
      t.references :project_pass_fail, index: true, foreign_key: { on_delete: :cascade }
      t.references :project_pass_fails_project, index: { name: :ppfc_ppfp_idx }, foreign_key: { on_delete: :cascade }
      t.references :client
      t.string :first_name
      t.string :last_name
      t.integer :disabling_condition
      t.integer :dob_quality
      t.date :dob
      t.integer :ethnicity
      t.integer :gender
      t.integer :name_quality
      t.jsonb :race
      t.boolean :any_races
      t.integer :ssn_quality
      t.string :ssn
      t.integer :veteran_status
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end
  end
end
