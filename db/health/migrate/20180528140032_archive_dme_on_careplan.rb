class ArchiveDmeOnCareplan < ActiveRecord::Migration
  def change
    add_column :careplans, :equipment_archive, :text
  end
end
