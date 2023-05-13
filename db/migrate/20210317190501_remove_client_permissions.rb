class RemoveClientPermissions < ActiveRecord::Migration[5.2]
  def up
    # give anyone with can_view_clients access group with all data sources
    # Move all deprecated role permissions to can_view_clients
    # remove old permissions (in a future migration)
    # User.joins(:roles).merge(Role.where(can_view_clients: true)).to_a.uniq do |user|
    #   AccessGroup.where(name: 'All Data Sources').first.users << user
    # end

    # # Give access the appropriate dashboard view
    # Role.all.each do |role|
    #   if role.can_view_clients
    #     role.update(can_view_full_client_dashboard: true)
    #   elsif role.can_view_client_window
    #     role.update(can_view_limited_client_dashboard: true)
    #   end
    # end

    # deprecated_permissions = [
    #   :can_edit_anything_super_user,
    #   :can_view_client_window,
    #   :can_see_clients_in_window_for_assigned_data_sources,
    #   :can_view_clients_with_roi_in_own_coc,
    # ]
    # # Upgrade, but don't yet disable old permissions so it can be rolled-back
    # deprecated_permissions.each do |perm|
    #   Role.where(perm => true).update_all(can_view_clients: true)
    # end
  end
end
