class AddContactMethodToVispdats < ActiveRecord::Migration[5.2]
  def change
    add_column :vispdats, :contact_method, :string
  end
end
