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

  def fetch_one(entity, permission)
    fetch([[entity, permission]]).first
  end

  # graphql's batch data loader identity. See Dataloader.batch_key_for
  def batch_loader_id
    "#{self.class.name}#{user.id}"
  end

  def roles_by_access_group_id
    @roles_by_access_group_id ||= user.roles
      .joins(:access_controls)
      .select('hmis_roles.*, hmis_access_controls.access_group_id AS access_group_id')
      .group_by(&:access_group_id)
  end

  # @param access_group_ids [Array<ID>, string]
  def access_groups_grant_permission?(access_group_ids, permission)
    access_group_ids.detect do |access_group_id|
      (roles_by_access_group_id[access_group_id] || []).detect do |role|
        role.grants?(permission)
      end
    end
  end

end
