module AccessControlSetup
  def setup_access_control(user, role, entity_group)
    user_group = UserGroup.where(name: "#{role.name} x #{entity_group.name}").first_or_create
    access_control = AccessControl.where(
      role_id: role.id,
      access_group_id: entity_group.id,
      user_group_id: user_group.id,
    ).first_or_create!
    access_control.add(user)
    user.access_groups.reload
    access_control
  end
end
