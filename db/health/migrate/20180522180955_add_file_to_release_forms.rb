class AddFileToReleaseForms < ActiveRecord::Migration
  def change
    add_column :release_forms, :file, :string
  end
end
