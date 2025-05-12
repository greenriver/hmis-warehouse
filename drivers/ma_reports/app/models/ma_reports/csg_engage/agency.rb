###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Agency < GrdaWarehouseBase
    self.table_name = :csg_engage_agencies
    has_many :programs, class_name: 'MaReports::CsgEngage::Program'
    has_many :program_mappings, through: :programs
  end
end
