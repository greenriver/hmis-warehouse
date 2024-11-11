module HopwaCaperHelpers
  include HmisCsvFixtures
  def create_report(projects)
    filter = ::Filters::HudFilterBase.new(
      project_ids: projects.map(&:id),
      start: report_start_date,
      end: report_end_date,
      user_id: user.id,
      coc_codes: [coc_code],
      funder_ids: HudUtility2024.funder_components.fetch('HUD: HOPWA'),
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

  def create_service(record_type:, fa_amount:, date_provided: nil, enrollment:, type_provided:)
    date_provided ||= enrollment.entry_date
    create(
      :hud_service,
      enrollment: enrollment,
      record_type: record_type,
      type_provided: type_provided,
      fa_amount: fa_amount,
      date_provided: date_provided,
      data_source: data_source,
    )
  end

  HopwaCaperTestHousehold = Struct.new(:hoh, :other_members, keyword_init: true) do
    def enrollments
      [hoh] + (other_members || [])
    end
  end

  def create_hopwa_eligible_household(project:, hoh_client: nil, other_clients: [])
    hoh_client ||= create(:hud_client, data_source: data_source)
    @household_id ||= 0
    @household_id += 1
    hoh_enrollment = create(
      :hud_enrollment,
      client: hoh_client,
      project: project,
      entry_date: report_start_date + 1.day,
      household_id: @household_id,
      relationship_to_hoh: 1,
    )

    other_members = other_clients.map do |client|
      create(
        :hud_enrollment,
        client: client,
        project: project,
        entry_date: report_start_date,
        household_id: @household_id,
        relationship_to_hoh: 99,
      )
    end

    # create(:grda_warehouse_service_history, :service_history_entry, client_id: hoh_client.id, first_date_in_program: hoh_enrollment.entry_date, enrollment: hoh_enrollment)

    # disability record sets the HOH as hopwa eligible
    create(
      :hud_disability,
      disability_type: hiv_positive,
      enrollment: hoh_enrollment,
      anti_retroviral: 1,
      viral_load_available: 1,
      viral_load: 100,
    )
    HopwaCaperTestHousehold.new(hoh: hoh_enrollment, other_members: other_members)
  end

  # help wrangle cell structure for test
  def question_as_rows(question_number:, report:)
    exporter = HudReports::CsvExporter.new(report, question_number)
    exporter.as_array
  end
end
