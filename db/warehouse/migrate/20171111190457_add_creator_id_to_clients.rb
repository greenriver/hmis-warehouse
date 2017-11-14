class AddCreatorIdToClients < ActiveRecord::Migration
  def change
    add_reference :Client, :creator, index: true
  end
end
