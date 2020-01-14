class ClientsRequireElevators < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :requires_elevator_access, :boolean, default: false
  end
end
