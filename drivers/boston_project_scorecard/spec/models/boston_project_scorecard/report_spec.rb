###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonProjectScorecard::Report, type: :model do
  before(:all) do
    cleanup_test_environment
  end

  after(:all) do
    cleanup_test_environment
  end

  let(:user) { create :user }
  let(:data_source) { create :grda_warehouse_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:project) do
    create(
      :hud_project,
      data_source: data_source,
      organization: organization,
      project_type: 13,
    )
  end
  let(:project_coc) do
    create(
      :hud_project_coc,
      data_source: data_source,
      project_id: project.project_id,
    )
  end

  let(:report) do
    described_class.create!(
      user: user,
      project: project,
      start_date: Date.new(2024, 10, 1),
      end_date: Date.new(2025, 9, 30),
      period_start_date: Date.new(2024, 10, 1),
      period_end_date: Date.new(2025, 9, 30),
    )
  end

  let(:apr_report) { double('APR Report', id: 1) }
  let(:comparison_apr_report) { double('Comparison APR Report', id: 2) }

  describe '#run_and_save!' do
    before do
      project_coc
      allow(report).to receive(:apr_report).and_return(apr_report)
      allow(report).to receive(:apr_compmarison_report).and_return(comparison_apr_report)

      # Mock answers for exits to permanent housing (RRH)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B43').and_return(0.65)
      allow(report).to receive(:answer).with(apr_report, 'Q5a', 'B2').and_return(100)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B40').and_return(20)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B41').and_return(5)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B42').and_return(10)

      # Mock answers for returns to homelessness
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B6').and_return(8)

      # Mock answers for employment income (stayers)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'H2').and_return(30)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'I2').and_return(10)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'J2').and_return(0.33)

      # Mock answers for other income (stayers)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'H4').and_return(50)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'D4').and_return(8)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'E4').and_return(4)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'F4').and_return(3)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'J4').and_return(0.30)

      # Mock answers for employment income (leavers)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'H2').and_return(20)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'I2').and_return(8)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'J2').and_return(0.40)

      # Mock answers for other income (leavers)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'H4').and_return(40)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'D4').and_return(6)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'E4').and_return(5)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'F4').and_return(4)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'J4').and_return(0.375)

      # Mock answers for days to lease up
      allow(report).to receive(:answer).with(apr_report, 'Q22c', 'B11').and_return(45.7)
      allow(report).to receive(:answer).with(comparison_apr_report, 'Q22c', 'B11').and_return(52.3)

      # Mock answers for data quality - PII error rate
      allow(report).to receive(:answer).with(apr_report, 'Q6a', anything).and_return(0.05)

      # UDE errors - 5 unique clients with errors out of 100 total served
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B2').and_return([1, 2])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B3').and_return([3])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B4').and_return([1])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B5').and_return([4, 5])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B6').and_return([])

      # Income and housing errors - 6 unique clients with errors
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B3').and_return((1..80).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B6').and_return((1..80).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B15').and_return((1..60).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B17').and_return((1..60).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B2').and_return([1, 2, 3])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B3').and_return([4, 5])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B4').and_return([6])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B5').and_return([])

      # Mock answers for utilization rate
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B2').and_return(0.85)
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B3').and_return(0.90)
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B4').and_return(0.88)
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B5').and_return(0.92)

      # Run once for all tests
      report.run_and_save!
    end

    # Project Performance Metrics
    it 'calculates rrh_exits_to_ph correctly' do
      expect(report.rrh_exits_to_ph).to eq(65.0)
    end

    it 'calculates psh_stayers_or_to_ph correctly' do
      # (100 - 20 + 5) / (100 - 10) = 85/90 = 0.9444 * 100 = 94.44%
      expect(report.psh_stayers_or_to_ph).to eq(94.44)
    end

    it 'calculates returns_to_homelessness correctly' do
      # 8 / (20 - 10) = 8/10 = 0.80 * 100 = 80%
      expect(report.returns_to_homelessness).to eq(80.0)
    end

    it 'calculates increased_stayer_employment_income correctly' do
      expect(report.increased_stayer_employment_income).to eq(33.0)
    end

    it 'calculates increased_stayer_other_income correctly' do
      expect(report.increased_stayer_other_income).to eq(30.0)
    end

    it 'calculates increased_leaver_employment_income correctly' do
      expect(report.increased_leaver_employment_income).to eq(40.0)
    end

    it 'calculates increased_leaver_other_income correctly' do
      expect(report.increased_leaver_other_income).to eq(37.5)
    end

    it 'calculates increased_employment_income correctly' do
      # (10 + 8) / (30 + 20) = 18/50 = 0.36 * 100 = 36%
      expect(report.increased_employment_income).to eq(36.0)
    end

    it 'calculates increased_other_income correctly' do
      # (8 + 4 + 3 + 6 + 5 + 4) / (50 + 40) = 30/90 = 0.3333 * 100 = 33.33%
      expect(report.increased_other_income).to eq(33.33)
    end

    it 'calculates days_to_lease_up correctly' do
      expect(report.days_to_lease_up).to eq(46)
    end

    it 'calculates days_to_lease_up_comparison correctly' do
      expect(report.days_to_lease_up_comparison).to eq(52)
    end

    # Data Quality Metrics
    it 'calculates pii_error_rate correctly' do
      expect(report.pii_error_rate).to eq(5.0)
    end

    it 'calculates ude_error_rate correctly' do
      # 5 unique clients / 100 total served = 5%
      expect(report.ude_error_rate).to eq(5.0)
    end

    it 'calculates income_and_housing_error_rate correctly' do
      # 6 unique clients / 80 in denominator = 7.5%
      expect(report.income_and_housing_error_rate).to eq(7.5)
    end

    # Financial Performance Metrics
    it 'calculates average_utilization_rate correctly' do
      # (0.85 + 0.90 + 0.88 + 0.92) / 4 = 0.8875
      expect(report.average_utilization_rate).to eq(0.8875)
    end

    # Metadata
    it 'sets status to pre-filled' do
      expect(report.status).to eq('pre-filled')
    end

    it 'sets project_type from project' do
      expect(report.project_type).to eq(13)
    end

    it 'sets apr_id and comparison_apr_id' do
      expect(report.apr_id).to eq(1)
      expect(report.comparison_apr_id).to eq(2)
    end
  end

  describe '#run_and_save! with edge cases' do
    before do
      project_coc
      allow(report).to receive(:apr_report).and_return(apr_report)
      allow(report).to receive(:apr_compmarison_report).and_return(comparison_apr_report)

      # Setup basic mocks
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B43').and_return(0.65)
      allow(report).to receive(:answer).with(apr_report, 'Q5a', 'B2').and_return(100)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B40').and_return(20)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B41').and_return(5)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B42').and_return(10)
      allow(report).to receive(:answer).with(apr_report, 'Q23c', 'B6').and_return(8)
      allow(report).to receive(:answer).with(apr_report, 'Q22c', 'B11').and_return(45.7)
      allow(report).to receive(:answer).with(comparison_apr_report, 'Q22c', 'B11').and_return(52.3)
      allow(report).to receive(:answer).with(apr_report, 'Q6a', anything).and_return(0.03)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B2').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B3').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B4').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B5').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6b', 'B6').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B3').and_return((1..80).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B6').and_return((1..80).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B15').and_return((1..60).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q5a', 'B17').and_return((1..60).to_a)
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B2').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B3').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B4').and_return([])
      allow(report).to receive(:answer_client_ids).with(apr_report, 'Q6c', 'B5').and_return([])
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B2').and_return(0.85)
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B3').and_return(0.90)
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B4').and_return(0.88)
      allow(report).to receive(:answer).with(apr_report, 'Q8b', 'B5').and_return(0.92)

      # Zero employment counts
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'H2').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'I2').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'J2').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'H4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'D4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'E4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'F4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a1', 'J4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'H2').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'I2').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'J2').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'H4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'D4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'E4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'F4').and_return(0)
      allow(report).to receive(:answer).with(apr_report, 'Q19a2', 'J4').and_return(0)
    end

    it 'handles zero employment counts without errors' do
      expect { report.run_and_save! }.not_to raise_error
      expect(report.increased_employment_income).to eq(0.0)
      expect(report.increased_other_income).to eq(0.0)
    end
  end
end
