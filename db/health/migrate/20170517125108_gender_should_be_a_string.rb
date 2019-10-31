class GenderShouldBeAString < ActiveRecord::Migration[4.2]
  def change
    remove_column :patients, :gender, :integer
    add_column :patients, :gender, :string
  end
end
