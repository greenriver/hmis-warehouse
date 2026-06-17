###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaReports::CsgEngage
  class Agency < GrdaWarehouseBase
    self.table_name = :csg_engage_agencies
    has_many :programs, class_name: 'MaReports::CsgEngage::Program'
    has_many :program_mappings, through: :programs
  end
end
