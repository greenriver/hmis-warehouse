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
      enrollments_index = enrollments.group_by(&:HouseholdID)
      households_scope.find_each do |hoh_enrollment|
        result << MaReports::CsgEngage::ReportComponents::Household.new(hoh_enrollment, enrollments_index[hoh_enrollment.HouseholdID])
      end
      result
    end

    private

    def project_ids
      @project_ids ||= program.program_mappings.pluck(:project_id)
    end

    def households_scope
      hh_ids = program.households_scope.limit(batch_size).offset(batch_size * batch_index).distinct(:HouseholdID).pluck(:HouseholdID)
      program.households_scope.where(HouseholdID: hh_ids).preload(project: [:project_cocs])
    end

    def enrollments
      hh_ids = households_scope.pluck(:HouseholdID)
      project_ids = households_scope.pluck(:ProjectID)
      program.enrollments_scope.where(HouseholdID: hh_ids, ProjectID: project_ids).preload(:client, :income_benefits, :services, :exit)
    end
  end
end
