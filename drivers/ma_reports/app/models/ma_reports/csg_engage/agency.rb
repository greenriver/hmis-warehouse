###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Agency < GrdaWarehouseBase
    self.table_name = :csg_engage_agencies
    has_many :program_mappings, class_name: 'MaReports::CsgEngage::ProgramMapping'
  end
end
