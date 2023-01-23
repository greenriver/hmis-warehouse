class AddSourceNameToHmisAssessment < ActiveRecord::Migration[4.2]
  def change
    table = GrdaWarehouse::Hmis::Assessment.table_name
    add_column table, :source_name, :string
  end
end
