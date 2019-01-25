class AddDeleteDetailToFiles < ActiveRecord::Migration
  def change
    add_column :files, :delete_detail, :string
  end
end
