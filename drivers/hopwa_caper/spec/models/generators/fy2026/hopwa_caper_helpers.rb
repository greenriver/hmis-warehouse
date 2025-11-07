###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaperHelpers
  include HmisCsvFixtures
  def create_report(projects)
    filter = ::Filters::HudFilterBase.new(
      project_ids: projects.map(&:id),
      start: report_start_date,
      end: report_end_date,
      user_id: user.id,
      coc_codes: [coc_code],
      funder_ids: HudHelper.util('2026').funder_components.fetch('HUD: HOPWA'),
    )
    ::HudReports::ReportInstance.from_filter(
      filter,
      generator.title,
      build_for_questions: generator.questions.keys,
    )
  end

  def run_report(report)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::ChEnrollment.maintain!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    generator.new(report).run!(email: false)
    report.reload
  end

  def create_hopwa_project(funder:)
    project = create(:hud_project, data_source: data_source, organization: organization)
    report_group.set_viewables({ projects: [project.id] })
    create(:hud_project_coc, project: project, data_source_id: data_source.id, CoCCode: coc_code)
    create(:hud_funder, project: project, funder: funder, data_source: data_source)
    project
  end

  # help wrangle cell structure for test
  def question_as_rows(question_number:, report:)
    exporter = HudReports::CsvExporter.new(report, question_number)
    exporter.as_array
  end
end
