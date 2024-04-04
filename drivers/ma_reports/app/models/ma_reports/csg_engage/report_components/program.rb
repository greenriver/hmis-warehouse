###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class Program < Base
    attr_accessor :program_mapping

    def initialize(program_mapping)
      @program_mapping = program_mapping
      @now = DateTime.current
    end

    field('Program Name') { program_mapping.csg_engage_name }
    field('Import Keyword') { program_mapping.csg_engage_import_keyword }

    field('Households') do
      result = []
      households_scope.find_each do |enrollment|
        result << MaReports::CsgEngage::ReportComponents::Household.new(enrollment)
      end
      result
    end

    private

    def project
      @project ||= program_mapping.project
    end

    def households_scope
      project.enrollments.heads_of_households.preload(project: [:project_cocs])
    end
  end
end
