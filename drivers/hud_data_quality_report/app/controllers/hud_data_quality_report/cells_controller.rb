###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  class CellsController < HudDataQualityReport::QuestionsController
    # Retired DQ years have no cell drilldowns. The route stays so path_for_cell resolves.
    prepend_before_action :not_authorized!
  end
end
