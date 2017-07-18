class AddProgramTypeToCasReports < ActiveRecord::Migration
  def change
    add_column :cas_reports, :program_type, :string
  end
end
