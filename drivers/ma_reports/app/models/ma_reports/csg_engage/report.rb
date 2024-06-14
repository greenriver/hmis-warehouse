###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Report < GrdaWarehouseBase
    include MaReports::CsgEngage::Concerns::HasReportStatus

    self.table_name = :csg_engage_reports
    has_many :program_reports, class_name: 'MaReports::CsgEngage::ProgramReport', inverse_of: :report
    belongs_to :agency, class_name: 'MaReports::CsgEngage::Agency'

    def self.build(agency)
      report = create(agency: agency, project_ids: agency.program_mappings.pluck(:project_id))
      agency.program_mappings.each do |program_mapping|
        MaReports::CsgEngage::ProgramReport.create(report: report, program_mapping: program_mapping)
      end
      report
    end

    def self.run_if_ready
      cred = MaReports::CsgEngage::Credential.first
      return unless cred.present?
      return unless DateTime.current.hour == cred.hour
      return if latest_report.present? && latest_report.started_at > DateTime.current - 20.hours

      MaReports::CsgEngage::Agency.find_each do |agency|
        report = MaReports::CsgEngage::Report.build(agency)
        report.delay.run
      end
    end

    def program_mappings
      @program_mappings ||= agency.program_mappings.
        preload(:project, :agency).
        preload(project: [:project_cocs]).
        preload(project: { enrollments: [:income_benefits, :services, :client] })
    end

    def run
      return if started?

      update(started_at: Time.zone.now, failed_at: nil, completed_at: nil)

      program_reports.each(&:run)
      cleanup
    end

    def respond_to_program_report_update(program_report)
      self.completed_at = program_report.completed_at if program_reports.all?(&:completed?)
      self.failed_at = program_report.failed_at if program_reports.any?(&:failed?)
      save!
    end

    def program_names
      program_reports.pluck(:imported_program_name).compact.uniq
    end

    def cleanup
      last_report = MaReports::CsgEngage::Report.order(:completed_at).where.not(id: id).last
      return unless last_report.present?

      last_report.program_reports.where(imported_program_name: last_report.program_names - program_names).find_each(&:delete_from_csg)
    end

    def self.latest_report
      where.not(completed_at: nil).order(:completed_at).last
    end

    def last_report
      MaReports::CsgEngage::Report.where.not(completed_at: nil).order(:completed_at).where.not(id: id).last
    end
  end
end
