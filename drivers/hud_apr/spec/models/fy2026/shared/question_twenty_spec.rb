###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe HudApr::Generators::Apr::Fy2026::QuestionTwenty, type: :model, exclude_fixpoints: true do
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
      build_for_questions: ['Question 20'],
    )
    report.question_names = ['Question 20']
    report.save!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    report
  end

  def run_q20(report)
    report.started_at ||= Time.current
    report.save! if report.changed?
    generator = HudApr::Generators::Apr::Fy2026::Generator.new(report)
    question = described_class.new(generator, report)
    question.run_question!
    report.reload
  end

  let(:es_project_type) { HudHelper.util('2026').project_type_number_from_code(:es).first }
  let(:project) { create_project(project_type: es_project_type) }

  # An adult (age > 17 at entry), HoH enrollment in the reporting period.
  def add_adult_enrollment(entry_date:, exit_date: nil)
    client = create_client_with_warehouse_link(dob: Date.new(1985, 1, 1))
    create_enrollment(
      client: client,
      project: project,
      entry_date: entry_date,
      exit_date: exit_date,
      relationship_to_ho_h: 1,
    )
  end

  # Snapshot fields key off (DataCollectionStage, InformationDate == EntryDate/ExitDate),
  # so callers must line those up with the stage they're exercising.
  def add_income_benefit(enrollment:, stage:, information_date:, **attrs)
    create(
      :hud_income_benefit,
      enrollment: enrollment,
      data_source: enrollment.data_source,
      InformationDate: information_date,
      DataCollectionStage: stage,
      **attrs,
    )
  end

  describe 'Q20b: Number of Non-Cash Benefit Sources' do
    # Per the HUD APR programming spec, a sub-source of 99 (Data Not Collected) does not override a
    # valid gate (BenefitsFromAnySource) = 0; the client belongs in "No Sources," not "Data Not
    # Collected." A gate = 0 with a real sub-source (SNAP = 1) still belongs in "1 + Source(s)".
    # Only a gate of 99 (or missing) legitimately routes a client into "Data Not Collected" (row 5).
    context 'at project start (column B)' do
      before do
        no_source = add_adult_enrollment(entry_date: Date.new(2026, 2, 1))
        add_income_benefit(
          enrollment: no_source,
          stage: 1,
          information_date: no_source.entry_date,
          BenefitsFromAnySource: 0,
          SNAP: 99,
        )

        with_source = add_adult_enrollment(entry_date: Date.new(2026, 2, 1))
        add_income_benefit(
          enrollment: with_source,
          stage: 1,
          information_date: with_source.entry_date,
          BenefitsFromAnySource: 0,
          SNAP: 1,
        )

        # Gate = 99 is the only genuine "Data Not Collected" client; it anchors the row 5 assertion.
        dnc = add_adult_enrollment(entry_date: Date.new(2026, 2, 1))
        add_income_benefit(
          enrollment: dnc,
          stage: 1,
          information_date: dnc.entry_date,
          BenefitsFromAnySource: 99,
        )

        @report = setup_apr_report([project.id])
        run_q20(@report)
      end

      it 'counts the gate=0/sub-source=99 client under "No Sources" (B2)' do
        expect(@report.answer(question: 'Q20b', cell: 'B2').summary).to eq(1)
      end

      it 'keeps the gate=0/sub-source=1 client in "1 + Source(s)" (B3), not "No Sources"' do
        expect(@report.answer(question: 'Q20b', cell: 'B3').summary).to eq(1)
      end

      # eq(1) rather than eq(0): with the genuine gate=99 client present, this asserts the true DNC
      # client lands in B5 AND (since the count is exactly 1) that the gate=0/sub-source=99 client
      # does not fall through to it. It fails both if the fix regresses (count becomes 2) and if the
      # row 5 catch-all stops selecting anyone (count becomes 0).
      it 'routes only the gate=99 client to "Data Not Collected" (B5), not the gate=0/sub-source=99 client' do
        expect(@report.answer(question: 'Q20b', cell: 'B5').summary).to eq(1)
      end
    end

    # The clause lives in the shared income_counts(suffix), so it drives the Exit column too — which
    # carries additional leaver/HoH filtering. Guard that the fix holds there as well.
    context 'at exit for leavers (column D)' do
      let(:exit_date) { Date.new(2026, 5, 1) }

      before do
        leaver = add_adult_enrollment(entry_date: Date.new(2026, 2, 1), exit_date: exit_date)
        add_income_benefit(
          enrollment: leaver,
          stage: 3,
          information_date: exit_date,
          BenefitsFromAnySource: 0,
          SNAP: 99,
        )

        # Gate = 99 leaver anchors the D5 assertion so it can distinguish "true DNC" from a regression.
        dnc_leaver = add_adult_enrollment(entry_date: Date.new(2026, 2, 1), exit_date: exit_date)
        add_income_benefit(
          enrollment: dnc_leaver,
          stage: 3,
          information_date: exit_date,
          BenefitsFromAnySource: 99,
        )

        @report = setup_apr_report([project.id])
        run_q20(@report)
      end

      it 'counts the gate=0/sub-source=99 leaver under "No Sources" (D2)' do
        expect(@report.answer(question: 'Q20b', cell: 'D2').summary).to eq(1)
      end

      it 'routes only the gate=99 leaver to "Data Not Collected" (D5), not the gate=0/sub-source=99 leaver' do
        expect(@report.answer(question: 'Q20b', cell: 'D5').summary).to eq(1)
      end
    end
  end
end
