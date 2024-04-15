###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Report < GrdaWarehouseBase
    self.table_name = :csg_engage_reports
    has_many :program_reports, class_name: 'MaReports::CsgEngage::ProgramReport', inverse_of: :report

    def self.build(program_mapping_scope = ProgramMapping.all)
      report = create(project_ids: program_mapping_scope.pluck(:project_id))
      program_mapping_scope.each do |program_mapping|
        MaReports::CsgEngage::ProgramReport.create(report: report, program_mapping: program_mapping)
      end
      report
    end

    def program_mappings
      @program_mappings ||= ProgramMapping.where(project_id: project_ids).
        preload(:project, :agency).
        preload(project: [:project_cocs]).
        preload(project: { enrollments: [:income_benefits, :services, :client] })
    end

    def run
      update(started_at: Time.zone.now, failed_at: nil, completed_at: nil)

      program_reports.each(&:run)
    end
  end
end
