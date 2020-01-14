class AddServiceArchiveToCareplans < ActiveRecord::Migration[4.2]
  def change
    add_column :careplans, :service_archive, :text
  end
end
