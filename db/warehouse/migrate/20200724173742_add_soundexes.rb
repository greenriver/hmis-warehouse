class AddSoundexes < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :soundex_first, :string
    add_column :Client, :soundex_last, :string
  end
end
