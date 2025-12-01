# frozen_string_literal: true

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

  # Create an HIV+ enrollment with standard disability attributes
  def create_hiv_positive_enrollment(client:, project:, entry_date:, household_id:, relationship_to_ho_h: 1, exit_date: nil, destination: nil)
    create_enrollment(
      client: client,
      project: project,
      entry_date: entry_date,
      household_id: household_id,
      relationship_to_ho_h: relationship_to_ho_h,
    ).tap do |enrollment|
      create(
        :hud_disability,
        disability_type: hiv_positive,
        enrollment: enrollment,
        anti_retroviral: 1,
        viral_load_available: 1,
        viral_load: 100,
        data_source: data_source,
        disability_response: 1,
      )
      if exit_date.present?
        create(
          :hud_exit,
          enrollment: enrollment,
          exit_date: exit_date,
          data_source: data_source,
          personal_id: client.personal_id,
          destination: destination,
        )
      end
    end
  end

  # Create client with enrollment and service in one call
  def create_enrolled_client_with_service(
    client_attrs:,
    project:,
    entry_date:,
    household_id: nil,
    relationship_to_ho_h: 1,
    service_type: nil,
    type_provided: nil,
    service_date: nil,
    fa_amount: 100
  )
    household_id ||= Hmis::Hud::Base.generate_uuid
    service_date ||= entry_date
    service_type ||= hopwa_financial_assistance
    type_provided ||= rental_assistance

    client = create(:hud_client, **client_attrs.merge(data_source: data_source))
    enrollment = create_hiv_positive_enrollment(
      client: client,
      project: project,
      entry_date: entry_date,
      household_id: household_id,
      relationship_to_ho_h: relationship_to_ho_h,
    )

    service = create(
      :hud_service,
      enrollment: enrollment,
      record_type: service_type,
      type_provided: type_provided,
      fa_amount: fa_amount,
      date_provided: service_date,
      data_source: data_source,
    )

    { client: client, enrollment: enrollment, service: service, household_id: household_id }
  end

  # Create standard income benefits (Medicaid + Earned income)
  def create_standard_income_benefits(enrollment, date: report_start_date)
    enrollment.income_benefits.create!(
      Medicaid: 1,
      Earned: 1,
      information_date: date,
    )
  end

  # Run report and extract rows as hash for given question
  def run_and_extract_rows(projects, question_number)
    report = create_report(projects)
    run_report(report)
    rows = question_as_rows(question_number: question_number, report: report).to_h
    [report, rows]
  end

  # HUD code lookup helper
  def hud_code(category, value)
    HudHelper.util('2026').public_send(category).invert.fetch(value)
  end
end
