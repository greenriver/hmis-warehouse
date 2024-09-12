###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class Program < Base
    attr_accessor :program, :batch_size, :batch_index

    def initialize(program, batch_size: 1000, batch_index: 0)
      @program = program
      @now = DateTime.current
      @batch_size = batch_size
      @batch_index = batch_index
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
      program.households_scope.limit(batch_size).offset(batch_size * batch_index).preload(project: [:project_cocs])
    end
  end
end
