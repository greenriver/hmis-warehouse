class ArchiveDmeOnCareplan < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :careplans, :equipment_archive, :text
  end
end
