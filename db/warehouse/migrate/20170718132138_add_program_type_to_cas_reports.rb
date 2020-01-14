class AddProgramTypeToCasReports < ActiveRecord::Migration[4.2]
  def change
    add_column :cas_reports, :program_type, :string
  end
end
