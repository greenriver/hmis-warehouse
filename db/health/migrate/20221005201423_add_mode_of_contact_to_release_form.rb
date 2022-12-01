class AddModeOfContactToReleaseForm < ActiveRecord::Migration[6.1]
  def change
    add_column :release_forms, :mode_of_contact, :string
  end
end
