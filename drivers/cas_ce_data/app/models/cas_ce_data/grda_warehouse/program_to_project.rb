###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasCeData::GrdaWarehouse
  class ProgramToProject < GrdaWarehouseBase
    self.table_name = 'cas_programs_to_projects'

    # belongs_to :program, optional: true
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
  end
end
