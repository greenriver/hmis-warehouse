###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

# A real APR run against real (minimal) HMIS data, rendered all the way to a real PDF,
# to directly answer: does Q4a's table still show all 17 columns (A through Q), in
# the correct left-to-right order, instead of the rightmost ones getting cut off?
#
# This checks the column-LETTER header row (A, B, C...) rather than reconstructing
# full per-column data.
RSpec.describe 'Q4a survives real PDF rendering', type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:organization) { create(:hud_organization, data_source: data_source, OrganizationName: 'ZZ_Q4A_REGRESSION_ORG_MARKER') }

  let(:report_start) { Date.new(2023, 10, 1) }
  let(:report_end) { Date.new(2024, 9, 30) }
  let(:es_project_type) { HudHelper.util('2024').project_type_number_from_code(:es).first }
  let(:project) { create_project(project_type: es_project_type) }

  HOUSEHOLD_COUNT = 5

  before do
    HOUSEHOLD_COUNT.times do
      client = create_client_with_warehouse_link(dob: Date.new(1985, 1, 1))
      create_enrollment(
        client: client,
        project: project,
        entry_date: report_start + 1.day,
        relationship_to_ho_h: 1,
      )
    end
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  let(:report) do
    filter = Filters::HudFilterBase.new(
      user: User.setup_system_user,
      start: report_start,
      end: report_end,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
    filter.update(project_ids: [project.id])
    # Only building for Question 4 ensures that only Q4a is rendered.
    # This makes it easier to find the correct header row.
    report = HudReports::ReportInstance.from_filter(
      filter,
      HudApr::Generators::Apr::Fy2024::Generator.title,
      build_for_questions: ['Question 4'],
    )
    report.question_names = ['Question 4']
    report.started_at ||= Time.current
    report.save!

    generator = HudApr::Generators::Apr::Fy2024::Generator.new(report)
    HudApr::Generators::Apr::Fy2024::QuestionFour.new(generator, report).run_question!
    report.reload
  end

  it 'computes the expected household count in the report answer API (sanity check before rendering)' do
    expect(report.answer(question: 'Q4a', cell: 'Q2').summary).to eq(HOUSEHOLD_COUNT)
  end

  it 'renders a real PDF where all Q4a columns (A through Q) survive, in order' do
    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    renderer = HudApr::AprsController.renderer.new(
      'warden' => PdfGenerator.warden_proxy(user),
    )
    html = renderer.render(
      'hud_reports/download',
      layout: 'layouts/hud_report_export',
      assigns: { report: report, generator: HudApr::Generators::Apr::Fy2024::Generator },
      formats: [:html],
    )

    pdf_data = PdfGenerator.new.render_pdf(html, options: { viewport: PdfGenerator::MEASUREMENT_VIEWPORT })
    file = Tempfile.new(['q4a_regression', '.pdf'])
    file.binmode
    file.write(pdf_data)
    file.close

    xml, status = Open3.capture2('pdftotext', '-bbox', file.path, '-')
    expect(status).to be_success

    # Extract all the words from the PDF, including their x and y positions.
    words = Nokogiri::XML(xml).css('word').map { |el| { text: el.text, x: el['xMin'].to_f, y: el['yMin'].to_f } }

    # The report is built via build_for_questions: ['Question 4'] above, so Q4a is the
    # only question hud_reports/download.haml renders (it only renders questions in
    # report.completed_questions) — no other table can appear in this PDF, so the only
    # A..Q header row present is necessarily Q4a's.
    #
    # The column-letter header row: single-character words spelling exactly A..Q, all
    # sharing one y value (rounded, to tolerate tiny floating-point jitter between renders).
    # If any column were clipped, its letter wouldn't be in this group at all.
    letter_groups = words.select { |w| w[:text].length == 1 && ('A'..'Q').cover?(w[:text]) }.group_by { |w| w[:y].round(1) }
    header_row = letter_groups.values.find { |ws| ws.map { |w| w[:text] }.sort == ('A'..'Q').to_a }
    expect(header_row).to be_present, 'could not find all column-letter headers (A..Q) together in the rendered PDF -- table may be clipped'

    ordered_letters = header_row.sort_by { |w| w[:x] }.map { |w| w[:text] }
    expect(ordered_letters).to eq(('A'..'Q').to_a)
  ensure
    file&.unlink
  end
end
