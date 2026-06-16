###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaReports::CsgEngage
  class ProgramMapping < GrdaWarehouseBase
    self.table_name = :csg_engage_program_mappings
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :program, class_name: 'MaReports::CsgEngage::Program'
    has_many :program_reports, through: :program

    scope :exportable, -> { where(include_in_export: true) }
  end
end
