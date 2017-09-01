class AddAggregateHealthRole < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: 'Health admin').update_all(
      can_view_aggregate_health: true, 
    )
  end
  def down
    remove_column :roles, :can_view_aggregate_health, :boolean, default: false
  end
end
