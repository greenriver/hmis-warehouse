###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  # Grants `role` on `projects` through ACLs (`:acl`) or legacy roles and access groups (`:legacy`)
  def grant_project_access(user, role, projects, mode:)
    if mode == :acl
      collection = create(:collection)
      collection.set_viewables({ projects: projects.map(&:id) })
      return setup_access_control(user, role, collection)
    end

    role.add(user)
    access_group = create(:access_group)
    access_group.add(user)
    projects.each { |project| access_group.add_viewable(project) }
    user.clear_memery_cache!
  end
end
