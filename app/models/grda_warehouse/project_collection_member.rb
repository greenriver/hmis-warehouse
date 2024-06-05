###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# DB view
module GrdaWarehouse
  class ProjectCollectionMember < GrdaWarehouseBase
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :collection, class_name: 'Collection'
  end
end
