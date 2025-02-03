###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO: START_ACL remove when ACL transition complete
module AccessGroups
  extend ActiveSupport::Concern

  ##
  # Returns a hash of relevant access groups for this entity.
  #
  # @note This method returns two sets:
  #   * 'Users'  => A collection of user-specific access groups
  #   * 'Groups' => A collection of general access groups
  #
  # @return [Hash{String => Array<AccessGroup>}] a hash mapping
  #   the groups ("Users", "Groups") to their respective access group arrays.
  def access_groups
    {
      'Users' => AccessGroup.user.merge(User.active).to_a,
      'Groups' => AccessGroup.general.to_a,
    }
  end

  ##
  # Retrieves the IDs of all access groups that currently include this record.
  #
  # @return [Array<Integer>] The list of group IDs that contain this entity.
  def access_group_ids
    AccessGroup.contains(self).pluck(:id)
  end

  ##
  # Updates the access groups for this record.
  #
  # Compares the provided +group_ids+ to the existing ones and:
  #   * Removes any previously assigned groups from groups that are no longer in +group_ids+
  #   * Ensures all groups in +group_ids+ are granted appropriate access
  #
  # @param group_ids [Array<Integer>] The IDs of the groups to which this record should belong.
  #
  # @return [void]
  def update_access(group_ids)
    removes = access_group_ids - group_ids
    AccessGroup.where(id: removes).each do |group|
      group.remove_viewable(self)
    end
    AccessGroup.where(id: group_ids).each do |group|
      group.add_viewable(self)
    end
  end

  ##
  # Marks this entity as deleted in all group viewable records.
  #
  # This prevents the entity from being viewed as part of any group.
  #
  # @return [void]
  def remove_from_group_viewable_entities!
    GrdaWarehouse::GroupViewableEntity.where(
      entity_type: self.class.sti_name,
      entity_id: id,
    ).update_all(deleted_at: Time.current)
  end
end
