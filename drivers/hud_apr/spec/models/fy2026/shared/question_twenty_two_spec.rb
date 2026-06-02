###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
end
