class RemoveFirstNameFromVispdats < ActiveRecord::Migration
  def change
    remove_column :vispdats, :first_name, :string
    remove_column :vispdats, :last_name, :string
    remove_column :vispdats, :ssn, :string
    remove_column :vispdats, :dob, :date
  end
end
