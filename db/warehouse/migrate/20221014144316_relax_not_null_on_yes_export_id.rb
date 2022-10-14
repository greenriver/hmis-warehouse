class RelaxNotNullOnYesExportId < ActiveRecord::Migration[6.1]
  def change
    change_column_null :YouthEducationStatus, :ExportID, true
  end
end
