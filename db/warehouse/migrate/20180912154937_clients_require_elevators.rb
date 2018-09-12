class ClientsRequireElevators < ActiveRecord::Migration
  def change
    add_column :Client, :requires_elevator_access, :boolean, default: false
  end
end
