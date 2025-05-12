module AccessControlSetup
  def setup_access_control(user, role, collection)
    user_group = UserGroup.where(name: "#{role.name} x #{collection.name}").first_or_create
    access_control = AccessControl.where(
      role_id: role.id,
      collection_id: collection.id,
      user_group_id: user_group.id,
    ).first_or_create!
    user_group.add(user)
    user.collections.reload
    user.clear_memery_cache!
    access_control
  end
end
