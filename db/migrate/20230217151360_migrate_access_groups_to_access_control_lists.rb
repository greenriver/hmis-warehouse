class MigrateAccessGroupsToAccessControlLists < ActiveRecord::Migration[6.1]
  # NOTE: Hmis::AccessGroupMember and Hmis::UserHmisDataSourceRole are now removed, so we shouldn't run this migration any more
  # def up
  #   processed_combinations = Set.new
  #   Hmis::Role.all.each do |role|
  #     Hmis::AccessGroup.all.each do |access_group|
  #       # Users that have this role and are in this group
  #       agm_scope = Hmis::AccessGroupMember.where(access_group_id: access_group.id)
  #       ushdr_scope = Hmis::UserHmisDataSourceRole.where(role_id: role.id)
  #       users = Hmis::User.where(id: agm_scope.pluck(:user_id)).merge(Hmis::User.where(id: ushdr_scope.pluck(:user_id)))
  #       next unless users.any?

  #       # Create ACL and add all users to it
  #       access_control_list = Hmis::AccessControl.create(role: role, access_group: access_group)
  #       users.each do |user|
  #         user.user_access_controls.find_or_create_by(user: user, access_control: access_control_list)
  #       end
  #     end
  #   end
  # end
end
