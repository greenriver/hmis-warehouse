###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class Program < Base
    attr_accessor :program

    def initialize(program)
      @program = program
      @now = DateTime.current
    end

    field('Program Name') { program.csg_engage_name }
    field('Import Keyword') { program.csg_engage_import_keyword }

    field('Households') do
      result = []
      households_scope.find_each do |enrollment|
        result << MaReports::CsgEngage::ReportComponents::Household.new(enrollment)
      end
      result
    end

    private

    def project_ids
      @project_ids ||= program.program_mappings.pluck(:project_id)
    end

    def households_scope
      GrdaWarehouse::Hud::Enrollment.joins(:project).where(project: { id: project_ids }).heads_of_households.preload(project: [:project_cocs])
    end
  end
end
