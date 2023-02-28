class MigrateAccessGroupsToAccessControlLists < ActiveRecord::Migration[6.1]
  def up
    Hmis::Role.all.each do |role|
      Hmis::AccessGroup.all.each do |access_group|
        # Users that have this role and are in this group
        agm_scope = Hmis::AccessGroupMember.where(access_group_id: access_group.id)
        ushdr_scope = Hmis::UserHmisDataSourceRole.where(role_id: role.id)
        users = Hmis::User.where(id: agm_scope.pluck(:user_id)).merge(Hmis::User.where(user_id: ushdr_scope.pluck(:user_id)))
        next unless users.any?
  
        # Create ACL and add all users to it
        access_control_list = Hmis::AccessControl.create(role: role, access_group: access_group)
        users.each do |user|
          user.user_access_controls.find_or_create_by(user: user, access_control: access_control_list)
        end

        # Ensure the data source is viewable to the access group
        GrdaWarehouse::DataSource.where(id: ushdr_scope.pluck(:data_source_id)).each do |ds|
          Hmis::GroupViewableEntity.find_or_create_by(access_group: access_group, entity: ds)
        end
      end
    end
  end
end
