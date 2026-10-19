###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Role-based (non-ACL) users. Project visibility comes from access groups, not collections.
module LegacyProjectNamesSetup
  LEGACY_NAME_ROLES = {
    names_and_view: { can_view_projects: true, can_view_confidential_project_names: true },
    names_only: { can_view_confidential_project_names: true },
    view_only: { can_view_projects: true },
  }.freeze

  def create_legacy_user(role_attributes, viewables)
    user = create(:user)
    create(:role, **role_attributes).add(user)
    access_group = create(:access_group)
    access_group.add(user)
    viewables.each { |viewable| access_group.add_viewable(viewable) }
    user.clear_memery_cache!
    user
  end
end
