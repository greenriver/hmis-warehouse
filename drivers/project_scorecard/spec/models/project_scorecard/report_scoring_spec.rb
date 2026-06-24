###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Unit tests for scoring methods changed/added in the FY2026 scoring update.
# These tests use Report.new with attributes set directly, and stub key_project
# with an OpenStruct to avoid requiring HUD DB records.
RSpec.describe ProjectScorecard::Report, 'scoring' do
  let(:report) { described_class.new }
  let(:psh_project) { OpenStruct.new(rrh?: false, psh?: true, sh?: false) }
  let(:rrh_project) { OpenStruct.new(rrh?: true,  psh?: false, sh?: false) }

  before { allow(report).to receive(:key_project).and_return(psh_project) }

  # --- Project Performance -------------------------------------------------

  describe '#utilization_score' do
    it 'returns nil regardless of utilization data' do
      report.utilization_jan = 100
      report.utilization_proposed = 100
      expect(report.utilization_score).to be_nil
    end
  end

  describe '#exit_to_ph_score' do
    context 'PSH project' do
      it 'scores 5 at the high threshold (>= 98%)' do
        allow(report).to receive(:exit_to_ph_percentage).and_return(98)
        expect(report.exit_to_ph_score).to eq(5)
      end

      it 'scores 3 in the mid range (90-97%)' do
        allow(report).to receive(:exit_to_ph_percentage).and_return(95)
        expect(report.exit_to_ph_score).to eq(3)
      end

      it 'scores 0 below the mid range (<= 89%)' do
        allow(report).to receive(:exit_to_ph_percentage).and_return(89)
        expect(report.exit_to_ph_score).to eq(0)
      end
    end

    context 'RRH project' do
      before { allow(report).to receive(:key_project).and_return(rrh_project) }

      it 'scores 5 at the high threshold (>= 95%)' do
        allow(report).to receive(:exit_to_ph_percentage).and_return(95)
        expect(report.exit_to_ph_score).to eq(5)
      end

      it 'scores 3 in the mid range (90-94%)' do
        allow(report).to receive(:exit_to_ph_percentage).and_return(90)
        expect(report.exit_to_ph_score).to eq(3)
      end

      it 'scores 0 below the mid range (<= 89%)' do
        allow(report).to receive(:exit_to_ph_percentage).and_return(89)
        expect(report.exit_to_ph_score).to eq(0)
      end
    end
  end

  describe '#leavers_los_score' do
    context 'RRH project' do
      before { allow(report).to receive(:key_project).and_return(rrh_project) }

      it 'scores 5 for 12 months in program (360 days)' do
        report.average_los_leavers = 360
        expect(report.leavers_los_score).to eq(5)
      end

      it 'scores 3 for 20 months in program (600 days)' do
        report.average_los_leavers = 600
        expect(report.leavers_los_score).to eq(3)
      end

      it 'scores 0 for 26 months in program (780 days)' do
        report.average_los_leavers = 780
        expect(report.leavers_los_score).to eq(0)
      end
    end

    context 'PSH project' do
      it 'returns nil (metric not applicable to PSH)' do
        report.average_los_leavers = 360
        expect(report.leavers_los_score).to be_nil
      end
    end
  end

  describe '#increased_employment_income_score' do
    context 'PSH project' do
      it 'scores 15 at >= 15%' do
        report.percent_increased_employment_income_at_exit = 15
        expect(report.increased_employment_income_score).to eq(15)
      end

      it 'scores 10 at 9-14%' do
        report.percent_increased_employment_income_at_exit = 9
        expect(report.increased_employment_income_score).to eq(10)
      end

      it 'scores 0 at <= 8%' do
        report.percent_increased_employment_income_at_exit = 8
        expect(report.increased_employment_income_score).to eq(0)
      end
    end

    context 'RRH project' do
      before { allow(report).to receive(:key_project).and_return(rrh_project) }

      it 'scores 15 at >= 56%' do
        report.percent_increased_employment_income_at_exit = 56
        expect(report.increased_employment_income_score).to eq(15)
      end

      it 'scores 10 at 50-55%' do
        report.percent_increased_employment_income_at_exit = 50
        expect(report.increased_employment_income_score).to eq(10)
      end

      it 'scores 0 at <= 49%' do
        report.percent_increased_employment_income_at_exit = 49
        expect(report.increased_employment_income_score).to eq(0)
      end
    end
  end

  describe '#returns_to_homelessness_score' do
    it 'scores 15 at <= 5%' do
      report.percent_returns_to_homelessness = 3
      expect(report.returns_to_homelessness_score).to eq(15)
    end

    it 'scores 10 at 6-15%' do
      report.percent_returns_to_homelessness = 10
      expect(report.returns_to_homelessness_score).to eq(10)
    end

    it 'scores 0 at >= 16%' do
      report.percent_returns_to_homelessness = 20
      expect(report.returns_to_homelessness_score).to eq(0)
    end
  end

  # --- Project Performance max ---------------------------------------------

  describe '#project_performance_max' do
    context 'RRH project' do
      before { allow(report).to receive(:key_project).and_return(rrh_project) }

      it 'returns 50 when returns to homelessness is scored' do
        report.percent_returns_to_homelessness = 3
        expect(report.project_performance_max).to eq(50)
      end

      it 'returns 35 when returns to homelessness data is unavailable' do
        report.percent_returns_to_homelessness = nil
        expect(report.project_performance_max).to eq(35)
      end
    end

    context 'PSH project' do
      it 'returns 45 when returns to homelessness is scored' do
        report.percent_returns_to_homelessness = 3
        expect(report.project_performance_max).to eq(45)
      end

      it 'returns 30 when returns to homelessness data is unavailable' do
        report.percent_returns_to_homelessness = nil
        expect(report.project_performance_max).to eq(30)
      end
    end
  end

  # --- Grant Management & Financials ---------------------------------------

  describe '#pit_participation_score' do
    it 'scores 5 when participating' do
      report.pit_participation = true
      expect(report.pit_participation_score).to eq(5)
    end

    it 'scores 0 when not participating' do
      report.pit_participation = false
      expect(report.pit_participation_score).to eq(0)
    end

    it 'returns nil when not yet answered' do
      report.pit_participation = nil
      expect(report.pit_participation_score).to be_nil
    end
  end

  describe '#supportive_services_score' do
    it 'scores 5 when yes' do
      report.supportive_services = true
      expect(report.supportive_services_score).to eq(5)
    end

    it 'scores 0 when no' do
      report.supportive_services = false
      expect(report.supportive_services_score).to eq(0)
    end

    it 'returns nil when not yet answered' do
      report.supportive_services = nil
      expect(report.supportive_services_score).to be_nil
    end
  end

  describe '#meetings_attended_score' do
    it 'scores 10 at >= 70%' do
      report.coc_meetings = 100
      report.coc_meetings_attended = 70
      expect(report.meetings_attended_score).to eq(10)
    end

    it 'scores 5 at 50-69%' do
      report.coc_meetings = 100
      report.coc_meetings_attended = 55
      expect(report.meetings_attended_score).to eq(5)
    end

    it 'scores 0 at <= 49%' do
      report.coc_meetings = 100
      report.coc_meetings_attended = 49
      expect(report.meetings_attended_score).to eq(0)
    end
  end

  # --- M&F aggregate -------------------------------------------------------

  describe '#m_and_f_score' do
    it 'includes supportive_services_score in the total' do
      allow(report).to receive(:spend_down_score).and_return(nil)
      allow(report).to receive(:cost_efficiency_score).and_return(nil)
      allow(report).to receive(:recaptured_score).and_return(nil)
      allow(report).to receive(:pit_participation_score).and_return(nil)
      allow(report).to receive(:meetings_attended_score).and_return(nil)
      report.supportive_services = true
      expect(report.m_and_f_score).to eq(5)
    end
  end
end
