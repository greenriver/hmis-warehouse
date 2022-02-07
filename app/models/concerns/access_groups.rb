###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AccessGroups
  extend ActiveSupport::Concern

  def access_groups
    {
      'Users' => AccessGroup.user.to_a,
      'Groups' => AccessGroup.general.to_a,
    }
  end

  def access_group_ids
    AccessGroup.contains(self).pluck(:id)
  end

  def update_access(group_ids)
    removes = access_group_ids - group_ids
    AccessGroup.where(id: removes).each do |group|
      group.remove_viewable(self)
    end
    AccessGroup.where(id: group_ids).each do |group|
      group.add_viewable(self)
    end
  end
end
