class AddCanSearchClients < ActiveRecord::Migration[6.1]
  def up
    Role.where(can_search_window: true).update_all(can_search_own_clients: true)
    Role.where(can_use_strict_search: true).update_all(can_search_own_clients: true)
    Role.where(can_search_all_clients: true).update_all(can_search_own_clients: true)
    # Add an ACL for anyone who could search the window to cover searching window data sources
    role = Role.create(name: 'Client Searcher', system: true, can_search_own_clients: true)
    entity_group = AccessGroup.system_access_group(:window_data_sources)
    user_group = UserGroup.create(name: 'Window Searchers')
    users = User.find_each.select { |u| u.can_search_window? }
    user_group.add(users)
    AccessControl.create(role: role, access_group: entity_group, user_group: user_group)
  end
end
