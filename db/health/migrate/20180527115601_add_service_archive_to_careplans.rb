class AddServiceArchiveToCareplans < ActiveRecord::Migration
  def change
    add_column :careplans, :service_archive, :text
  end
end
