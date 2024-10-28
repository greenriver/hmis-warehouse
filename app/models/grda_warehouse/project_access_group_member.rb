###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This DB view finds project and access group relationships. It includes access groups that relate to the project
# indirectly (via organization, project groups, etc)
module GrdaWarehouse
  class ProjectAccessGroupMember < GrdaWarehouseBase
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :access_group, class_name: 'AccessGroup'
  end
end
