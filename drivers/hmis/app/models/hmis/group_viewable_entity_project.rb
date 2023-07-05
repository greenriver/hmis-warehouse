###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# DB view
module Hmis
  class GroupViewableEntityProject < GrdaWarehouseBase
    belongs_to :group_viewable_entity
    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :organization, class_name: 'Hmis::Hud::Organization'
    def readonly
      true
    end
  end
end
