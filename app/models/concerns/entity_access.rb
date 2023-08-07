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
  #   2. first or create a collection for the cohort called "Cohort X" and add the user to it
  #   3. first or create an access control that includes above role and collection
  #   4. add user to the access control
  # NOTE: this will remove any existing who are not included
  def replace_access(users, scope:)
    users = Array.wrap(users)
    # Ensure access controls are present
    viewable_access_control
    editable_access_control

    user_group = case scope
    when :editor
      system_editable_user_group
    when :viewer
      system_viewable_user_group
    else
      raise 'Unknown access type'
    end
    to_remove = user_group.users - users
    user_group.remove(to_remove) if to_remove.present?
    user_group.add(users) if users.present?
  end

  def viewable_access_control
    @viewable_access_control ||= AccessControl.where(
      collection: system_entity_group,
      role: viewable_role,
      user_group: system_viewable_user_group,
    ).first_or_create
  end

  def editable_access_control
    @editable_access_control ||= AccessControl.where(
      collection: system_entity_group,
      role: editable_role,
      user_group: system_editable_user_group,
    ).first_or_create
  end

  def system_entity_group
    @system_entity_group ||= Collection.where(system: ['Entities'], name: name).first_or_create
  end

  def system_viewable_user_group
    @system_viewable_user_group ||= UserGroup.where(system: true, name: "#{name} [viewable]").first_or_create
  end

  def system_editable_user_group
    @system_editable_user_group ||= UserGroup.where(system: true, name: "#{name} [editable]").first_or_create
  end

  def viewable_role
    @viewable_role ||= Role.system.where(name: viewable_role_name, viewable_permission => true).first_or_create
  end

  def editable_role
    @editable_role ||= Role.system.where(name: editable_role_name, editable_permission => true).first_or_create
  end

  private def editable_permissions
    self.class.editable_permissions
  end

  private def viewable_permissions
    self.class.viewable_permissions
  end

  private def editable_permission
    self.class.editable_permission
  end

  private def viewable_permission
    self.class.viewable_permission
  end

  def users_with_access(access_type:)
    collection_ids = group_viewable_entities.pluck(:collection_id)
    return [] unless collection_ids

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
    User.diet.
      joins(:roles, :collections).
      where(Arel.sql(ors.join(' or '))).
      merge(Collection.where(id: collection_ids)).to_a.uniq
  end
end
