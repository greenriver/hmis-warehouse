class AddUserIdToClients < ActiveRecord::Migration
  def change
    add_reference :Client, :user, index: true
  end
end
