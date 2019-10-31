class AddUserIdToVispdats < ActiveRecord::Migration[4.2]
  def change
    add_reference :vispdats, :user, index: true
  end
end
