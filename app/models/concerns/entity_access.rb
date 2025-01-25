###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

##
# The +EntityAccess+ concern provides methods for managing user access (either
# viewable or editable) to a given model. It is currently in-use in ProjectGroups and Cohorts
# It ensures that each entity has a system collection, user groups for viewing/editing,
# and the associated roles that grant the correct permissions.
#
module EntityAccess
  extend ActiveSupport::Concern

  # Replace the current users who have a specified access level with a new set
  # of users. Determines whether to modify the "editable" or "viewable" group
  # based on +scope+.
  #
  # @param [Array<User>, User] users
  #   The user or array of users to be granted the specified access.
  # @param [Symbol] scope
  #   The access type to update, one of +:editor+ or +:viewer+.
  #
  # @raise [RuntimeError]
  #   Raises an error if +scope+ is not recognized.
  #
  # @return [void]
  #
  def replace_access(users, scope:)
    users = Array.wrap(users)

    user_group = case scope
    when :editor
      editable_access_control # Ensure access controls are present
      system_editable_user_group
    when :viewer
      viewable_access_control # Ensure access controls are present
      system_viewable_user_group
    else
      raise 'Unknown access type'
    end
    to_remove = user_group.users - users
    user_group.remove(to_remove) if to_remove.present?
    user_group.add(users) if users.present?
  end

  ##
  # Retrieves (or creates) the +AccessControl+ record that grants "viewable"
  # permission for this entity's system collection.
  #
  # @return [AccessControl]
  #
  def viewable_access_control
    @viewable_access_control ||= AccessControl.where(
      collection: system_collection,
      role: viewable_role,
      user_group: system_viewable_user_group,
    ).first_or_create!
  end

  ##
  # Retrieves (or creates) the +AccessControl+ record that grants "editable"
  # permission for this entity's system collection.
  #
  # @return [AccessControl]
  #
  def editable_access_control
    @editable_access_control ||= AccessControl.where(
      collection: system_collection,
      role: editable_role,
      user_group: system_editable_user_group,
    ).first_or_create!
  end

  ##
  # Finds or creates a "system" +Collection+ dedicated to this entity.
  # The collection will only contain one group-viewable entity (this one). It
  # also updates the collection's name to match the entity's +name+.
  # Note that updating the name may cause an extra query, and in the future we may wan to
  # refactor that into an after save hook or similar.
  #
  # @return [Collection]
  #
  def system_collection
    @system_collection ||= begin
      collection = Collection.system.where(source: self).first_or_initialize do |c|
        c.name = name
        c.system = ['Entities'] # required to indicate it is a system collection
        c.collection_type = collection_type # indicate which type of collection this is
        c
      end
      # ensure the collection name still matches
      collection.update!(name: name)
      collection.set_viewables(entity_relation_type => [id])
      collection
    end
  end

  ##
  # Finds or creates a "system" +UserGroup+ that grants viewable access
  # to this entity to users through the `viewable_access_control``.
  # It updates the group's name to be "<entity name> [viewable]".
  # Note that updating the name may cause an extra query, and in the future we may wan to
  # refactor that into an after save hook or similar.
  #
  # @return [UserGroup]
  #
  def system_viewable_user_group
    @system_viewable_user_group ||= begin
      ug = UserGroup.system.where(source: self, context: :viewable).first_or_initialize
      # Maintain the name
      ug.update!(name: viewable_user_group_name)
      ug
    end
  end

  ##
  # Finds or creates a "system" +UserGroup+ that grants editable access
  # to this entity to users through the `editable_access_control``.
  # It updates the group's name to be "<entity name> [editable]".
  # Note that updating the name may cause an extra query, and in the future we may wan to
  # refactor that into an after save hook or similar.
  #
  # @return [UserGroup]
  #
  def system_editable_user_group
    @system_editable_user_group ||= begin
      ug = UserGroup.system.where(source: self, context: :editable).first_or_initialize
      # Maintain the name
      ug.update!(name: editable_user_group_name)
      ug
    end
  end

  ##
  # Finds or creates a "system" +Role+ that has the "viewable" permission
  # set to +true+.
  #
  # @return [Role]
  #
  def viewable_role
    @viewable_role ||= Role.system.where(name: viewable_role_name, viewable_permission => true).first_or_create!
  end

  ##
  # Finds or creates a "system" +Role+ that has the "editable" permission
  # set to +true+.
  #
  # @return [Role]
  #
  def editable_role
    @editable_role ||= Role.system.where(name: editable_role_name, editable_permission => true).first_or_create!
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

  private def viewable_user_group_name
    "#{name} [viewable]"
  end

  private def editable_user_group_name
    "#{name} [editable]"
  end

  ##
  # Returns all users with the specified +access_type+ to this entity. This may
  # include any user with either "viewable" or "editable" permissions, depending
  # on the requested +access_type+.
  #
  # @param [Symbol] access_type
  #   The type of access to filter by (:view, :edit, or :access).
  # @raise [RuntimeError]
  #   Raises an error if +access_type+ is unknown.
  #
  # @return [Array<User>]
  #   The unique list of users who have the specified type of access.
  #
  def users_with_access(access_type:)
    collection_ids = group_viewable_entities.where.not(collection_id: nil).pluck(:collection_id)
    return [] unless collection_ids

    permissions = case access_type
    when :view
      viewable_permissions
    when :edit
      editable_permissions
    when :access
      viewable_permissions + editable_permissions
    else
      raise 'Unknown access type'
    end

    ors = permissions.map do |perm|
      r_t[perm].eq(true).to_sql
    end
    role_ids = Role.where(Arel.sql(ors.join(' or '))).pluck(:id)

    # FIXME: Need all Access Controls that contain one of the roles, one of the collections, then get their users

    User.diet.
      joins(:access_controls).
      merge(AccessControl.where(role_id: role_ids, collection_id: collection_ids)).to_a.uniq
  end
end
