class AddUserIdToVispdats < ActiveRecord::Migration
  def change
    add_reference :vispdats, :user, index: true
  end
end
