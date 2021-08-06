class AddManualRecordToInventoryFunderProjectCoC < ActiveRecord::Migration[5.2]
  def change
    add_column 'Inventory', :manual_entry, :boolean, default: false
    add_column 'Funder', :manual_entry, :boolean, default: false
    add_column 'ProjectCoC', :manual_entry, :boolean, default: false
  end
end
