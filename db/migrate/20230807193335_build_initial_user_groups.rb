class BuildInitialUserGroups < ActiveRecord::Migration[6.1]
  def up
    Hmis::AccessControl.find_each do |ac|
      ug = Hmis::UserGroup.create(name: "Users from access control: #{ac.id}")
      user_ids = Hmis::UserAccessControl.where(access_control_id: ac.id).pluck(:user_id)
      data = user_ids.map { |id| { user_group_id: ug.id, user_id: id } }
      Hmis::UserGroupMember.import(data)
      ac.update(user_group_id: ug.id)
    end
  end
end
