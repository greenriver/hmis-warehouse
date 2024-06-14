class AddCsgEngageProgramMappings < ActiveRecord::Migration[6.1]
  def change
    create_table(:csg_engage_program_mappings) do |t|
      t.timestamps
      t.belongs_to :project, to_table: :Project, index: true
      t.string :clarity_name
      t.string :csg_engage_name
      t.string :csg_engage_import_keyword
      t.boolean :include_in_export, null: false, default: true
      t.belongs_to :agency, to_table: :csg_engage_agencies, index: true
    end

    create_table(:csg_engage_agencies) do |t|
      t.timestamps
      t.string :name
      t.integer :csg_engage_agency_id
    end

    create_table(:csg_engage_reports) do |t|
      t.timestamps
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.string :project_ids, array: true, null: false, default: []
      t.belongs_to :agency, to_table: :csg_engage_agencies, index: true
    end
  end
end
