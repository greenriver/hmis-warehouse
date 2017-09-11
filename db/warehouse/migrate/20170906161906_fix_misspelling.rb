class FixMisspelling < ActiveRecord::Migration
  def change
    rename_column :Client, :assylee, :asylee
  end
end
