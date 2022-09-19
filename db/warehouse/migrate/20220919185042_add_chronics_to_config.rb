class AddChronicsToConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :chronic_tab_justifications, :boolean, default: true
    add_column :configs, :chronic_tab_roi, :boolean
  end
end
