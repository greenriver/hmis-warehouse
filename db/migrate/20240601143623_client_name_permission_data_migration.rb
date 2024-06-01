class ClientNamePermissionDataMigration < ActiveRecord::Migration[7.0]
  # data migration only
  disable_ddl_transaction!

  # preserve current ability to see client name for roles that can search/view clients
  def up
    view_cond = <<~SQL
      can_view_clients = true OR
      can_edit_clients = true OR
      can_search_clients_with_roi = true OR
      can_search_window = true OR
      can_search_own_clients = true OR
      can_search_all_clients = true
    SQL
    Role.where(view_cond).
      where.not('name ILIKE ?', '%Green River%').
      update_all(can_view_client_name: true)
    User.clear_cached_permissions
  end

  def down
    # no-op
  end
end
