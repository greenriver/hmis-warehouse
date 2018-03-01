class AddAttributesToFiles < ActiveRecord::Migration
  def change
    add_column :files, :size, :float
  end
end
