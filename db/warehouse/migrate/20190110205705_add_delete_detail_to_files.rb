class AddDeleteDetailToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :delete_detail, :string
  end
end
