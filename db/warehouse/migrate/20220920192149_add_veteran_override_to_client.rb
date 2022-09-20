class AddVeteranOverrideToClient < ActiveRecord::Migration[6.1]
  def change
    add_column :Client, :veteran_override, :boolean, default: false
    add_column :Client, :va_check_date, :date, default: nil
  end
end
