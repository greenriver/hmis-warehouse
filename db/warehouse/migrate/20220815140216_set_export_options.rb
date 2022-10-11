class SetExportOptions < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::HmisExport.for_list.each do |ex|
      ex.update(options: {project_ids: ex.project_ids})
    end
  end
end
