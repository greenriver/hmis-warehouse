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
    process_imported_fixtures(skip_location_cleanup: true)
    generator.new(report).run!(email: false)
    report.reload
  end

  def create_hopwa_project(funder:)
    project = create(:hud_project, data_source: data_source)
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

  HopwaCaperTextHousehold = Struct.new(:hoh, :spouse, keyword_init: true)
  def create_hopwa_eligible_household(project:)
    hoh = create(:hud_client, data_source: data_source)
    @household_id ||= 0
    @household_id += 1
    enrollment = create(:hud_enrollment, client: hoh, project: project, entry_date: report_start_date, household_id: @household_id, relationship_to_hoh: 1)

    # FIXME: not sure how we generate "service history enrollments"
    create(:grda_warehouse_service_history, :service_history_entry, client_id: hoh.id, first_date_in_program: enrollment.entry_date, enrollment: enrollment)

    create(:hud_disability, disability_type: hiv_positive, enrollment: enrollment)
    HopwaCaperTextHousehold.new(hoh: enrollment)
  end

  # help wrangle cell structure for test
  def question_as_rows(question_number:, report:)
    exporter = HudReports::CsvExporter.new(report, question_number)
    exporter.as_array
  end

  # row[][] => table[row_label][col_label]
  def rows_to_table(rows)
    result = {}
    rows = rows.map(&:dup)
    column_labels = rows.shift[1..] # Remove and store column labels, excluding the first element

    rows.each do |row|
      row_label = row.shift # Remove and store row label
      result[row_label] = {}

      row.each_with_index do |value, index|
        result[row_label][column_labels[index]] = value
      end
    end

    result
  end
end
