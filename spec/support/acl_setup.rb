module AclSetup
  def setup_acl(user, role, group)
    acl = AccessControl.where(
      role_id: role.id,
      access_group_id: group.id,
    ).first_or_create!
    acl.add(user)
  end
end
