###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# DB view

module Hmis
  class GroupViewableEntityProject < GrdaWarehouseBase
    belongs_to :group_viewable_entity
    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :organization, class_name: 'Hmis::Hud::Organization'
    # belongs_to :project_group, class_name: 'Hmis::ProjectGroup'
    # belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    def readonly
      true
    end
  end
end
