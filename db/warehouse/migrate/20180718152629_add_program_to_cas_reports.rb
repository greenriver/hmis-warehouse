class AddProgramToCasReports < ActiveRecord::Migration
  def change
    add_column :cas_reports, :program_name, :string
    add_column :cas_reports, :sub_program_name, :string
  end
end
