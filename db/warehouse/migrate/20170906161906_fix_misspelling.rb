class FixMisspelling < ActiveRecord::Migration[4.2]
  def change
    rename_column :Client, :assylee, :asylee
  end
end
