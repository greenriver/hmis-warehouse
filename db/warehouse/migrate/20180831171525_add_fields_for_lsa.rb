class AddFieldsForLsa < ActiveRecord::Migration[4.2]
  def change
    add_column :Project, :operating_start_date_override, :date
    add_column :Geography, :information_date_override, :date
  end
end
