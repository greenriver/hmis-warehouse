###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasCeEvents::GrdaWarehouse
  class ProgramToProject < GrdaWarehouseBase
    self.table_name = 'cas_programs_to_projects'

    # belongs_to :program
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
  end
end
