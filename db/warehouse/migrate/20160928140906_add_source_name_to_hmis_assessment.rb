class AddSourceNameToHmisAssessment < ActiveRecord::Migration
  def change
    table = GrdaWarehouse::HMIS::Assessment.table_name
    add_column table, :source_name, :string
  end
end
