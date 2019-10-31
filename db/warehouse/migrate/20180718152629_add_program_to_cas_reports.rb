class AddProgramToCasReports < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :program_name, :string
    add_column :cas_reports, :sub_program_name, :string
  end
end
