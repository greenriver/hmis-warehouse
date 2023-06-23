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
end
