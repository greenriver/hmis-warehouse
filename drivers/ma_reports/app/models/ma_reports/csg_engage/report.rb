###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Report < GrdaWarehouseBase
    self.table_name = :csg_engage_reports

    def self.build_from_scope(program_mapping_scope = ProgramMapping.all)
      create(project_ids: program_mapping_scope.pluck(:project_id))
    end

    def program_mappings
      MaReports::CsgEngage::ReportComponents::Report.preloaded_program_mappings(ProgramMapping.where(project_id: project_ids))
    end

    def run
      update(started_at: Time.zone.now, failed_at: nil, completed_at: nil)

      # TODO: Handle external calls
      program_mappings.map { |pm| MaReports::CsgEngage::ReportComponents::Report.new(pm) }
    end
  end
end
