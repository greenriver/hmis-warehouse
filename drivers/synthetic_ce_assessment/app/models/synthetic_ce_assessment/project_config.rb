###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SyntheticCeAssessment
  class ProjectConfig < GrdaWarehouseBase
    has_paper_trail
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'

    scope :active, -> do
      where(active: true)
    end
  end
end
