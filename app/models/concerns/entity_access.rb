###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EntityAccess
  extend ActiveSupport::Concern

  # Ensure this user has the appropriate access to this item
  # Need two cohort users choosers, editors and read-only users
  # If I created a cohort: (put this on the cohort object - accepts users)
  #   1. first or create a system role with can_view_cohorts "System Role - Can View Cohorts"
  #   2. first or create a group for the cohort called "Cohort X" and add the user to it
  #   3. first or create an access control that includes above role and group
  #   4. add user to the access control
  # NOTE: this will remove any existing who are not included
  def replace_access(users, scope:)
    acl = case scope
    when :editor
      editable_acl
    when :viewer
      viewable_acl
    else
      raise 'Unknown access type'
    end
    to_remove = acl.users - users
    acl.remove(to_remove) if to_remove.present?
    acl.add(Array.wrap(users)) if users.present?
  end

  def viewable_acl
    @viewable_acl ||= AccessControl.where(access_group: system_group, role: viewable_role).first_or_create
  end

  def editable_acl
    @editable_acl ||= AccessControl.where(access_group: system_group, role: editable_role).first_or_create
  end

  def system_group
    @system_group ||= AccessGroup.where(system: ['Entities'], name: name).first_or_create
  end

  def viewable_role
    @viewable_role ||= Role.system.where(name: viewable_role_name, viewable_permission => true).first_or_create
  end

  def editable_role
    @editable_role ||= Role.system.where(name: editable_role_name, editable_permission => true).first_or_create
  end

  def users_with_access(access_type:)
    access_group_ids = group_viewable_entities.pluck(:access_group_id)
    return [] unless access_group_ids

    permissions = case access_type
    when :view
      viewable_permissions
    when :edit
      editable_permissions
    else
      raise 'Unknown access type'
    end

    ors = permissions.map do |perm|
      r_t[perm].eq(true).to_sql
    end
    User.diet.distinct.
      joins(:roles, :access_groups).
      where(Arel.sql(ors.join(' or '))).
      merge(AccessGroup.where(id: access_group_ids)).to_a
  end
end
