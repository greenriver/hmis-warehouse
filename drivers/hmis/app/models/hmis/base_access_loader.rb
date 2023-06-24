###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::BaseAccessLoader
  attr_accessor :user
  def initialize(user)
    self.user = user
  end

  # helper object to prevent pollution
  def arel
    @arel ||= Hmis::BaseAccessLoader::ArelHelper.new
  end

  class Hmis::BaseAccessLoader::ArelHelper
    include Hmis::Concerns::HmisArelHelper
  end

  def fetch_one(entity, permission)
    fetch([[entity, permission]]).first
  end

  # graphql's batch data loader identity. See Dataloader.batch_key_for
  def batch_loader_id
    "#{self.class.name}:#{user.id}"
  end

  def validate_items(items, expected_type)
    items.each do |record, _|
      raise "unexpected #{record.class.name}, expected #{expected_type}" unless record.is_a?(expected_type)
      raise "unexpected unsaved #{record.class.name}" unless record.persisted?
    end
  end

  # the user's roles grouped by the role's access_group_id
  # @return [Hash{access_group_id, Array<Hmis::Role>}]]
  def user_roles_by_access_group_id
    @user_roles_by_access_group_id ||= user.roles
      .joins(:access_controls)
      .select('hmis_roles.*, hmis_access_controls.access_group_id AS access_group_id')
      .group_by(&:access_group_id)
  end

  # find the intersection the user's roles, access_groups, and a permission
  # @param access_group_ids [Array<ID>] the access groups for an entity
  # @param permission [PermissionId]
  def user_access_groups_grant_permission?(access_group_ids, permission)
    found = access_group_ids.detect do |access_group_id|
      (user_roles_by_access_group_id[access_group_id] || []).detect do |role|
        role.grants?(permission)
      end
    end
    !!found
  end
end
