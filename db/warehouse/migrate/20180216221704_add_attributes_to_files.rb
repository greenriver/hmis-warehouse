class AddAttributesToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :size, :float
  end
end
