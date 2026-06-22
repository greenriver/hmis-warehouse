###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SyntheticCeAssessment
  class ProjectConfig < GrdaWarehouseBase
    has_paper_trail
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'

    scope :active, -> do
      where(active: true)
    end
  end
end
