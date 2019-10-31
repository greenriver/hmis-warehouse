class AddCreatorIdToClients < ActiveRecord::Migration[4.2]
  def change
    add_reference :Client, :creator, index: true
  end
end
