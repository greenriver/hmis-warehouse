class UpdateCsgProgramReportToUseMultipleMappings < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :csg_engage_programs do |t|
        t.references :agency
        t.string :csg_engage_name, null: false
        t.string :csg_engage_import_keyword, null: false
        t.timestamps
      end

      add_reference :csg_engage_program_mappings, :program
      add_reference :csg_engage_program_reports, :program

      remove_column :csg_engage_program_mappings, :csg_engage_name, :string
      remove_column :csg_engage_program_mappings, :csg_engage_import_keyword, :string
      remove_reference :csg_engage_program_mappings, :agency
      remove_reference :csg_engage_program_reports, :program_mapping
    end
  end
end
