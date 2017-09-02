class AddClientHistoryPermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin ) ).update_all(
      can_view_client_history_calendar: true
    )
  end
  def down
    remove_column :roles, :can_view_client_history_calendar, :boolean, default: false
  end
end
