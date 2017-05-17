class GenderShouldBeAString < ActiveRecord::Migration
  def change
    remove_column :patients, :gender, :integer
    add_column :patients, :gender, :string
  end
end
