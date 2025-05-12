###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This DB view finds project and collection relationships. It includes access groups that relate to the project
# indirectly (via organization, project groups, etc)
module GrdaWarehouse
  class ProjectCollectionMember < GrdaWarehouseBase
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :collection, class_name: 'Collection'
  end
end
