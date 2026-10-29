###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::Generators::CeApr::Fy2026::QuestionNine do
  let(:report) do
    create(
      :hud_reports_report_instance,
      build_for_questions: [described_class::QUESTION_NUMBER],
      remaining_questions: [described_class::QUESTION_NUMBER],
    )
  end
  let(:generator) { HudApr::Generators::CeApr::Fy2026::Generator.new(report) }
  let(:question) { described_class.new(generator, report) }

  describe 'Q9b prioritization status' do
    before do
      members = [1, 2, nil].to_h do |status|
        apr_client = create(
          :hud_report_apr_client,
          report_instance: report,
          head_of_household: true,
          household_type: :adults_only,
          ce_assessment_date: Date.new(2025, 1, 1),
          ce_assessment_prioritization_status: status,
        )
        [create(:grda_warehouse_hud_client), apr_client]
      end
      report.universe(described_class::QUESTION_NUMBER).add_universe_members(members)

      question.run_question!
    end

    it 'counts households with no prioritization status as not placed on the list' do
      expect(report.answer(question: 'Q9b', cell: 'B2').summary).to eq(1)
      expect(report.answer(question: 'Q9b', cell: 'B3').summary).to eq(2)
    end

    it 'includes households with no prioritization status in the percent prioritized' do
      expect(report.answer(question: 'Q9b', cell: 'B4').summary).to eq('0.3333')
    end
  end
end
