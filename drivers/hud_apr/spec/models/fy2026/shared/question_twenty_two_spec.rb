###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe HudApr::Generators::Apr::Fy2026::QuestionTwentyTwo, type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:report_start) { Date.new(2025, 10, 1) }
  let(:report_end) { Date.new(2026, 9, 30) }

  let(:apr_filter) do
    Filters::HudFilterBase.new(
      user: User.setup_system_user,
      start: report_start,
      end: report_end,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
  end

  def setup_apr_report(project_ids)
    filter = apr_filter.dup
    filter.update(project_ids: project_ids)
    report = HudReports::ReportInstance.from_filter(
      filter,
      HudApr::Generators::Apr::Fy2026::Generator.title,
      build_for_questions: ['Question 22'],
    )
    report.question_names = ['Question 22']
    report.save!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    report
  end

  def run_q22(report)
    report.started_at ||= Time.current
    report.save! if report.changed?
    generator = HudApr::Generators::Apr::Fy2026::Generator.new(report)
    question = described_class.new(generator, report)
    question.run_question!
    report.reload
  end

  describe 'Q22c: Average length of time to housing' do
    # Report period: 2025-10-01 to 2026-09-30
    #
    # Client 1: 31 days to move-in (entry 2025-10-01, move-in 2025-11-01)
    # Client 2: 61 days to move-in (entry 2025-10-01, move-in 2025-12-01)
    # Client 3: 800 days to move-in (entry 2023-08-14, move-in 2025-10-22)
    #
    #           → exceeds the 730-day max bucket, must NOT inflate the average
    #
    # Correct average = (31 + 61) / 2 = 46

    before do
      psh_project_type = HudHelper.util('2026').project_type_number_from_code(:psh).first
      @project = create_project(project_type: psh_project_type)

      client1 = create_client_with_warehouse_link(dob: Date.new(1985, 1, 1))
      create_enrollment(
        client: client1,
        project: @project,
        entry_date: Date.new(2025, 10, 1),
        move_in_date: Date.new(2025, 11, 1), # 31 days
        relationship_to_ho_h: 1,
      )

      client2 = create_client_with_warehouse_link(dob: Date.new(1990, 6, 1))
      create_enrollment(
        client: client2,
        project: @project,
        entry_date: Date.new(2025, 10, 1),
        move_in_date: Date.new(2025, 12, 1), # 61 days
        relationship_to_ho_h: 1,
      )

      # Client enrolled 800 days before their move-in date — exceeds the 730-day bucket cap.
      # This client should be excluded from the Row 12 average and Row 11 total.
      client3 = create_client_with_warehouse_link(dob: Date.new(1975, 3, 15))
      create_enrollment(
        client: client3,
        project: @project,
        entry_date: Date.new(2023, 8, 14),
        move_in_date: Date.new(2025, 10, 22), # 800 days after entry
        relationship_to_ho_h: 1,
      )

      @report = setup_apr_report([@project.id])
      run_q22(@report)
    end

    it 'excludes clients with >730 days from the average (Row 12)' do
      # (31 + 61) / 2 = 46, not (31 + 61 + 800) / 3 = 297
      expect(@report.answer(question: 'Q22c', cell: 'B12').summary).to eq(46)
    end

    it 'excludes clients with >730 days from total persons moved into housing (Row 11)' do
      expect(@report.answer(question: 'Q22c', cell: 'B11').summary).to eq(2)
    end

    it 'excludes clients with >730 days from total persons (Row 14)' do
      # Client 3 has move_in_date (not a leaver without move-in) but time_to_move_in > 730,
      # so they appear in neither the "moved into housing" nor the "exited without move-in" rows.
      expect(@report.answer(question: 'Q22c', cell: 'B14').summary).to eq(2)
    end
  end

  # Q22c row letters: B2 '7 days or less' ... B6 '31 to 60 days', B7 '61 to 90 days',
  # B10 '366 to 730 days', B11 total moved into housing, B12 average, B13 exited
  # without move-in, B14 total persons.
  describe 'Q22c: household move-in date inheritance' do
    let(:psh_project_type) { HudHelper.util('2026').project_type_number_from_code(:psh).first }
    let(:household_id) { Hmis::Hud::Base.generate_uuid }

    before { @project = create_project(project_type: psh_project_type) }

    def run!
      @report = setup_apr_report([@project.id])
      run_q22(@report)
    end

    def answer(cell)
      @report.answer(question: 'Q22c', cell: cell).summary
    end

    describe 'a member who exited before the household moved into housing' do
      # HoH: entry 2025-10-01, move-in 2025-12-01 => 61 days.
      # Member: entry 2025-10-01, exited 2025-11-01, before the household was housed,
      # so per the glossary they do not inherit the HoH move-in date.
      before do
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1985, 1, 1)),
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          move_in_date: Date.new(2025, 12, 1),
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1988, 2, 2)),
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          exit_date: Date.new(2025, 11, 1),
          relationship_to_ho_h: 2,
          household_id: household_id,
        )
        run!
      end

      it 'reports only the HoH as moved into housing (B11)' do
        expect(answer('B11')).to eq(1)
      end

      it 'reports the member as exited without move-in (B13)' do
        expect(answer('B13')).to eq(1)
      end

      it 'counts both clients once across the reconciling rows (B14)' do
        expect(answer('B14')).to eq(2)
      end
    end

    describe 'a member whose own move-in date precedes their project start' do
      # HoH: entry 2025-10-01, move-in 2025-11-01 => 31 days.
      # Member: entry 2025-10-01 with an own move-in date of 2025-09-15. The glossary
      # says to disregard it, leaving the member to inherit the HoH date => 31 days.
      before do
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1985, 1, 1)),
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          move_in_date: Date.new(2025, 11, 1),
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1988, 2, 2)),
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          move_in_date: Date.new(2025, 9, 15),
          relationship_to_ho_h: 2,
          household_id: household_id,
        )
        run!
      end

      it 'reports both clients in the 31 to 60 days bucket (B6)' do
        expect(answer('B6')).to eq(2)
      end

      it 'reports both clients as moved into housing (B11)' do
        expect(answer('B11')).to eq(2)
      end

      it 'averages 31 days (B12)' do
        expect(answer('B12')).to eq(31)
      end
    end

    describe 'a member whose own move-in date falls after the report end' do
      # HoH: entry 2025-10-01, move-in 2025-11-01 => 31 days.
      # Member: entry 2025-10-01 with an own move-in date of 2026-10-15, after the
      # 2026-09-30 report end. Disregarded, so the member inherits => 31 days.
      before do
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1985, 1, 1)),
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          move_in_date: Date.new(2025, 11, 1),
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1988, 2, 2)),
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          move_in_date: Date.new(2026, 10, 15),
          relationship_to_ho_h: 2,
          household_id: household_id,
        )
        run!
      end

      it 'reports both clients in the 31 to 60 days bucket (B6)' do
        expect(answer('B6')).to eq(2)
      end

      it 'leaves the 366 to 730 days bucket empty (B10)' do
        expect(answer('B10')).to eq(0)
      end

      it 'averages 31 days (B12)' do
        expect(answer('B12')).to eq(31)
      end
    end

    describe 'a household whose HoH has an earlier reported HoH enrollment' do
      # The HoH heads two in-range enrollments. The earlier, exited stay carries a
      # move-in date of 2025-10-05; the current household has no move-in date at all.
      # Nobody in the current household has moved into housing, so the earlier stay's
      # date must not leak into the current household's members.
      let(:earlier_household_id) { Hmis::Hud::Base.generate_uuid }

      before do
        hoh = create_client_with_warehouse_link(dob: Date.new(1985, 1, 1))
        create_enrollment(
          client: hoh,
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          move_in_date: Date.new(2025, 10, 5),
          exit_date: Date.new(2025, 11, 1),
          relationship_to_ho_h: 1,
          household_id: earlier_household_id,
        )
        create_enrollment(
          client: hoh,
          project: @project,
          entry_date: Date.new(2026, 1, 1),
          exit_date: Date.new(2026, 5, 1),
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1988, 2, 2)),
          project: @project,
          entry_date: Date.new(2026, 1, 1),
          exit_date: Date.new(2026, 5, 1),
          relationship_to_ho_h: 2,
          household_id: household_id,
        )
        run!
      end

      it 'reports nobody from the current household as moved into housing (B11)' do
        expect(answer('B11')).to eq(0)
      end

      it 'reports both members of the current household as exited without move-in (B13)' do
        expect(answer('B13')).to eq(2)
      end
    end

    describe 'a member who joined after the household was housed' do
      # Glossary rule 3: a late joiner's move-in date is their own project start date,
      # so they legitimately contribute 0 days. Pinned so it is not "fixed" later.
      before do
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1985, 1, 1)),
          project: @project,
          entry_date: Date.new(2025, 10, 1),
          move_in_date: Date.new(2025, 11, 1),
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
        create_enrollment(
          client: create_client_with_warehouse_link(dob: Date.new(1988, 2, 2)),
          project: @project,
          entry_date: Date.new(2025, 12, 1),
          relationship_to_ho_h: 2,
          household_id: household_id,
        )
        run!
      end

      it 'reports the late joiner at 0 days (B2)' do
        expect(answer('B2')).to eq(1)
      end

      it 'reports both clients as moved into housing (B11)' do
        expect(answer('B11')).to eq(2)
      end
    end
  end
end
