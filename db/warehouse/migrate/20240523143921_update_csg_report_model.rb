class UpdateCsgReportModel < ActiveRecord::Migration[7.0]
  def change
    add_column :csg_engage_program_reports, :imported_program_name, :string
    add_column :csg_engage_program_reports, :imported_import_keyword, :string
    add_column :csg_engage_program_reports, :cleared_at, :string
  end
end
