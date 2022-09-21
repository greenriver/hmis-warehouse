class RenameVeteranOverride < ActiveRecord::Migration[6.1]
  def change
    rename_column :Client, :veteran_override, :va_verified_veteran?
  end
end
