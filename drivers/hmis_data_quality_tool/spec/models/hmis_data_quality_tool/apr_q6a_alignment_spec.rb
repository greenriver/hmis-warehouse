###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../spec/shared_contexts/hud_enrollment_builders'

# Runs the DQ Tool, the APR (Q6a) and the standalone HMIS DQ Report (Q2) over one set of
# clients and asserts the three agree on which clients are PII errors.
#
# The APR's Q6a and the DQ Report's Q2 are the same code: both call generate_q2 from the
# shared Dq::QuestionTwo concern, only the table name differs.
#
# The generators are resolved as the current ones rather than pinned to a fiscal year,
# because the DQ Tool's limiters call HudHelper.util with no version argument and so always
# follow that same switch. Pinning the APR side here would mean that the first year the
# current version rolls forward, this spec would compare the current DQ Tool against a stale
# APR and keep passing. If the version rolls before the matching generator or question
# exists, resolving it raises, which is the intended signal to re-check the alignment.
#
# The fixtures are curated so the three structural differences between the reports cannot
# affect the comparison: the project is not Street Outreach (so Q6a's engaged_clause drops
# nobody), every client has exactly one source client (the DQ Tool counts source clients,
# the APR counts one row per client), and every client is the head of its own single-member
# household with one enrollment (Q6a applies some DOB rules only to heads of household, and
# only to one enrollment per client).
RSpec.describe 'DQ Tool and APR Q6a PII alignment', type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  # Both resolve off HudReports::BaseController#default_report_version, the same switch the
  # DQ Tool's own unversioned HudHelper.util calls follow. HudApr.current_generator has no
  # :dq case, so the DQ Report is looked up the way its controller does.
  let(:report_version) { HudReports::BaseController.new.default_report_version }
  let(:apr_generator) { HudApr.current_generator(report: :apr) }
  let(:dq_report_generator) { HudApr::Dq::DqConcern.possible_generator_classes.fetch(report_version) }

  # Generators key their questions by question number.
  let(:apr_question) { apr_generator.questions.fetch('Question 6') }
  let(:dq_report_question) { dq_report_generator.questions.fetch('Question 2') }

  let(:es_project_type) { HudHelper.util.project_type_number_from_code(:es).first }
  let(:report_start) { Date.new(2025, 10, 1) }
  let(:report_end) { Date.new(2026, 9, 30) }
  let(:entry_date) { Date.new(2025, 12, 1) }
  let(:exit_date) { Date.new(2026, 2, 1) }

  # The DQ Tool resolves projects through the viewing user's collections; the APR side uses
  # the system user, as its own specs do. Both see every fixture project.
  let(:dq_tool_user) { create(:acl_user) }
  let(:apr_user) { User.setup_system_user }
  let!(:reporting_role) do
    create(
      :role,
      name: 'DQ Tool / APR alignment role',
      can_view_project_related_filters: true,
      can_view_assigned_reports: true,
      can_view_projects: true,
      can_view_clients: true,
      can_search_own_clients: true,
    )
  end
  let(:data_sources_collection) { Collection.system_collection(:data_sources) }

  # Distinct SSNs that pass HudHelper.util.valid_social? — no zero-filled group, and none is
  # a rotation or reverse of 0123456789.
  let(:valid_ssns) do
    [
      '123456780', '223456780', '323456780', '423456780', '523456780', '623456780',
      '723456780', '823456780', '133456780', '143456780', '153456780', '163456780'
    ].each
  end

  before do
    HmisDataQualityTool::Client.destroy_all
    HmisDataQualityTool::Enrollment.destroy_all
    HmisDataQualityTool::Report.destroy_all
    setup_access_control(dq_tool_user, reporting_role, data_sources_collection)
    dq_tool_user.clear_memery_cache!
  end

  # Every element valid unless the caller perturbs exactly one of them.
  def create_aligned_client(last_name, **overrides)
    attrs = {
      first_name: 'Valid',
      last_name: last_name,
      ssn: valid_ssns.next,
      dob: Date.new(1990, 1, 1),
    }.merge(overrides)
    client = create_client_with_warehouse_link(**attrs)
    enrollment = create_enrollment(
      client: client,
      project: @project,
      entry_date: entry_date,
      exit_date: exit_date,
    )
    create_bed_night_service(enrollment: enrollment, date: entry_date + 1.day)
    client
  end

  def base_filter(user)
    Filters::HudFilterBase.new(
      user: user,
      start: report_start,
      end: report_end,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
      require_service_during_range: false,
    )
  end

  def run_dq_tool_report(project_ids)
    filter = base_filter(dq_tool_user)
    filter.update(project_ids: project_ids)

    report = HmisDataQualityTool::Report.new(
      user_id: dq_tool_user.id,
      report_name: HmisDataQualityTool::Report.untranslated_title,
      manual: true,
      question_names: [],
    )
    report.filter = filter
    report.save!
    report.run_and_save!
    report.reload
  end

  def run_hud_question(project_ids, generator_class, question_class, questions)
    filter = base_filter(apr_user)
    filter.update(project_ids: project_ids)

    report = HudReports::ReportInstance.from_filter(
      filter,
      generator_class.title,
      build_for_questions: questions,
    )
    report.question_names = questions
    report.started_at ||= Time.current
    report.save!

    question_class.new(generator_class.new(report), report).run_question!
    report.reload
  end

  # The DQ Tool keys its sections by title; the HUD reports key column E (the per-element
  # total) by row: Name is row 2, SSN row 3, DOB row 4.
  ELEMENTS = {
    name: { dq_tool_section: 'Name', hud_row: 2 },
    ssn: { dq_tool_section: 'Social Security Number', hud_row: 3 },
    dob: { dq_tool_section: 'DOB', hud_row: 4 },
  }.freeze

  def dq_tool_flagged(report, element)
    report.items_for(ELEMENTS[element][:dq_tool_section]).map(&:destination_client_id).to_set
  end

  def hud_flagged(report, table, element)
    report.answer(question: table, cell: "E#{ELEMENTS[element][:hud_row]}").
      universe_members.preload(:universe_membership).
      map { |member| member.universe_membership.destination_client_id }.to_set
  end

  def destination_ids(*clients)
    clients.map { |client| client.warehouse_client_source.destination_id }.to_set
  end

  context 'with clients whose errors the aligned criteria both recognize' do
    before do
      @project = create_project(project_type: es_project_type)

      @clean = create_aligned_client('Clean')

      @dob_doesnt_know = create_aligned_client('DobDoesntKnow', dob_data_quality: 8)
      @dob_refused = create_aligned_client('DobRefused', dob_data_quality: 9)
      @dob_approximate = create_aligned_client('DobApproximate', dob_data_quality: 2)
      @dob_absent = create_aligned_client('DobAbsent', dob: nil, dob_data_quality: 99)
      @dob_before_1915 = create_aligned_client('DobBefore1915', dob: Date.new(1914, 12, 31))

      @ssn_approximate = create_aligned_client('SsnApproximate', ssn_data_quality: 2)
      @ssn_absent = create_aligned_client('SsnAbsent', ssn: nil, ssn_data_quality: 1)
      @ssn_not_valid = create_aligned_client('SsnNotValid', ssn: '123456789')

      @name_doesnt_know = create_aligned_client('NameDoesntKnow', name_data_quality: 8)
      @name_not_collected = create_aligned_client('NameNotCollected', name_data_quality: 99)
      @name_absent = create_aligned_client('NameAbsent', last_name: nil, name_data_quality: 1)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

      @dq_tool_report = run_dq_tool_report([@project.id])
      @apr = run_hud_question([@project.id], apr_generator, apr_question, ['Question 6'])
      @dq_report = run_hud_question([@project.id], dq_report_generator, dq_report_question, ['Question 2'])
    end

    it 'includes every client in all three reports' do
      expect(@dq_tool_report.clients.count).to eq(12)
      expect(@apr.universe(apr_question::QUESTION_NUMBER).members.count).to eq(12)
    end

    it 'flags the same clients for Name' do
      expected = destination_ids(@name_doesnt_know, @name_not_collected, @name_absent)

      expect(dq_tool_flagged(@dq_tool_report, :name)).to eq(expected)
      expect(hud_flagged(@apr, 'Q6a', :name)).to eq(expected)
      expect(hud_flagged(@dq_report, 'Q2', :name)).to eq(expected)
    end

    it 'flags the same clients for SSN' do
      expected = destination_ids(@ssn_approximate, @ssn_absent, @ssn_not_valid)

      expect(dq_tool_flagged(@dq_tool_report, :ssn)).to eq(expected)
      expect(hud_flagged(@apr, 'Q6a', :ssn)).to eq(expected)
      expect(hud_flagged(@dq_report, 'Q2', :ssn)).to eq(expected)
    end

    it 'flags the same clients for DOB' do
      expected = destination_ids(
        @dob_doesnt_know,
        @dob_refused,
        @dob_approximate,
        @dob_absent,
        @dob_before_1915,
      )

      expect(dq_tool_flagged(@dq_tool_report, :dob)).to eq(expected)
      expect(hud_flagged(@apr, 'Q6a', :dob)).to eq(expected)
      expect(hud_flagged(@dq_report, 'Q2', :dob)).to eq(expected)
    end

    it 'leaves a client with no PII errors out of all three reports' do
      clean = destination_ids(@clean).first

      ELEMENTS.each_key do |element|
        expect(dq_tool_flagged(@dq_tool_report, element)).not_to include(clean)
        expect(hud_flagged(@apr, 'Q6a', element)).not_to include(clean)
        expect(hud_flagged(@dq_report, 'Q2', element)).not_to include(clean)
      end
    end
  end

  context 'with clients the DQ Tool flags but Q6a cannot' do
    before do
      @project = create_project(project_type: es_project_type)

      @clean = create_aligned_client('Clean')

      # Q6a partitions Name on name_quality with NOT IN, and SQL drops NULL rows from that.
      @null_name_quality = create_aligned_client('NullNameQuality')
      @null_name_quality.update(NameDataQuality: nil)

      # Q6a tests first_name IS NULL, which an empty string is not.
      @empty_first_name = create_aligned_client('EmptyFirstName', first_name: '', name_data_quality: 1)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

      @dq_tool_report = run_dq_tool_report([@project.id])
      @apr = run_hud_question([@project.id], apr_generator, apr_question, ['Question 6'])
    end

    it 'flags a NULL Name Data Quality and an empty first name' do
      expect(dq_tool_flagged(@dq_tool_report, :name)).to eq(destination_ids(@null_name_quality, @empty_first_name))
    end

    it 'is the only one of the two reports that does' do
      expect(hud_flagged(@apr, 'Q6a', :name)).to be_empty
    end
  end
end
