###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaReports::CsgEngage
  class Program < GrdaWarehouseBase
    self.table_name = :csg_engage_programs
    belongs_to :agency, class_name: 'MaReports::CsgEngage::Agency'
    has_many :program_reports, class_name: 'MaReports::CsgEngage::ProgramReport'
    has_many :program_mappings, class_name: 'MaReports::CsgEngage::ProgramMapping'
  end
end
