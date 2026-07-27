###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonProjectScorecard::Report, type: :model do
  include ActiveJob::TestHelper

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

  let(:secondary_reviewer) { nil }
  let(:report) do
    described_class.create!(
      user: user,
      project: project,
      start_date: Date.new(2024, 10, 1),
      end_date: Date.new(2025, 9, 30),
      period_start_date: Date.new(2024, 10, 1),
      period_end_date: Date.new(2025, 9, 30),
      secondary_reviewer: secondary_reviewer,
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
      allow(report).to receive(:answer).with(apr_report, 'Q6a', report.pii_error_cell).and_return(0.05)

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

    # Policy alignment Q18 (utilization rate)
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
      allow(report).to receive(:answer).with(apr_report, 'Q6a', report.pii_error_cell).and_return(0.03)
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

  describe 'score availability by project type' do
    subject(:report) do
      project = create(
        :hud_project,
        data_source: data_source,
        organization: organization,
        project_type: project_type,
      )
      create(
        :hud_project_coc,
        data_source: data_source,
        project_id: project.project_id,
      )
      described_class.create!(
        user: user,
        project: project,
        start_date: Date.new(2024, 10, 1),
        end_date: Date.new(2025, 9, 30),
        period_start_date: Date.new(2024, 10, 1),
        period_end_date: Date.new(2025, 9, 30),
        project_type: project_type,
      )
    end

    shared_examples 'scorecard category weights' do
      it 'uses the expected category weights' do
        expect(report.project_performance_weight).to eq(50)
        expect(report.data_quality_weight).to eq(5)
        expect(report.financial_performance_weight).to eq(20)
        expect(report.policy_alignment_weight).to eq(25)
        expect(report.total_score_weight).to eq(100)
      end
    end

    context 'when non-RRH/PSH' do
      let(:project_type) { 1 } # Emergency Shelter

      include_examples 'scorecard category weights'

      it 'uses the non-housing maximum points' do
        expect(report.project_performance_available).to eq(48)
        expect(report.data_quality_available).to eq(15)
        expect(report.financial_performance_available).to eq(18)
        expect(report.policy_alignment_available).to eq(31)
        expect(report.total_score_available).to eq(112)
      end
    end

    context 'when RRH' do
      let(:project_type) { 13 }

      include_examples 'scorecard category weights'

      it 'uses the RRH maximum points' do
        expect(report.project_performance_available).to eq(60)
        expect(report.data_quality_available).to eq(15)
        expect(report.financial_performance_available).to eq(20)
        expect(report.policy_alignment_available).to eq(34)
        expect(report.total_score_available).to eq(129)
      end
    end

    context 'when PSH' do
      let(:project_type) { 3 }

      include_examples 'scorecard category weights'

      it 'uses the PSH maximum points' do
        expect(report.project_performance_available).to eq(60)
        expect(report.data_quality_available).to eq(15)
        expect(report.financial_performance_available).to eq(20)
        expect(report.policy_alignment_available).to eq(37)
        expect(report.total_score_available).to eq(132)
      end
    end
  end

  describe 'section scoring' do
    let(:report) do
      described_class.create!(
        user: user,
        project: project,
        start_date: Date.new(2024, 10, 1),
        end_date: Date.new(2025, 9, 30),
        period_start_date: Date.new(2024, 10, 1),
        period_end_date: Date.new(2025, 9, 30),
        project_type: 13,
      )
    end

    before { project_coc }

    before do
      report.update!(days_to_lease_up: 100)
    end

    it 'scores monitoring criteria in policy alignment, not project performance' do
      report.update!(project_type: 1, no_concern: 2)

      expect(report.project_performance_score).to eq(0)
      expect(report.policy_alignment_score).to eq(2)
    end

    it 'scores utilization in policy alignment when households served are present' do
      report.update!(project_type: 1, average_utilization_rate: 90.0, actual_households_served: 100)

      expect(report.utilization_rate_score).to eq(6)
      expect(report.project_performance_score).to eq(0)
      expect(report.policy_alignment_score).to eq(6)
    end

    it 'awards only one monitoring score when both Q19a and Q19b are set' do
      report.update!(no_concern: 2, materials_concern: 3)

      expect(report.policy_alignment_score).to eq(5) # Q14 RRH (3) + Q19a (2)
    end

    it 'excludes not-applicable monitoring responses from scoring' do
      report.update!(no_concern: -1, materials_concern: -1)

      expect(report.policy_alignment_score).to eq(3) # Q14 RRH only
      expect(report.policy_alignment_available).to eq(31) # 34 - 3 for Q19a/Q19b N/A
    end

    it 'awards 2 points for RRH cost efficiency when under the threshold' do
      report.update!(amount_agency_spent: 10_000, actual_households_served: 10)

      expect(report.efficiency_score).to eq(2)
    end

    it 'does not award cost efficiency points for non-housing project types' do
      report.update!(
        project_type: 1,
        amount_agency_spent: 10_000,
        actual_households_served: 10,
      )

      expect(report.efficiency_score).to eq(0)
      expect(report.financial_performance_available).to eq(18)
    end

    it 'does not exceed the category weight at maximum policy alignment score' do
      report.update!(
        subpopulations_served: report.subpopulations_served_options.values,
        substance_use_treatment_service: report.substance_use_treatment_service_options.values,
        supportive_services: true,
        no_concern: 3,
        average_utilization_rate: 90.0,
        actual_households_served: 100,
      )

      expect(report.policy_alignment_score).to eq(report.policy_alignment_available)
      expect(report.policy_alignment_weighted_score).to eq(report.policy_alignment_weight)
    end

    it 'reduces policy alignment available when both monitoring questions are not applicable' do
      report.update!(no_concern: -1, materials_concern: -1)

      expect(report.policy_alignment_available).to eq(31)
      expect(report.total_score_available).to eq(126)
    end

    it 'reduces policy alignment available for non-housing projects when both monitoring questions are not applicable' do
      report.update!(project_type: 1, no_concern: -1, materials_concern: -1)

      expect(report.policy_alignment_available).to eq(28)
      expect(report.total_score_available).to eq(109)
    end

    it 'awards rrh_exits_to_ph_score at each point threshold' do
      report.update!(rrh_exits_to_ph: 75)
      expect(report.rrh_exits_to_ph_score).to eq(12)

      report.update!(rrh_exits_to_ph: 55)
      expect(report.rrh_exits_to_ph_score).to eq(6)

      report.update!(rrh_exits_to_ph: 25)
      expect(report.rrh_exits_to_ph_score).to eq(4)

      report.update!(rrh_exits_to_ph: 24)
      expect(report.rrh_exits_to_ph_score).to eq(0)
    end

    it 'awards psh_stayers_or_to_ph_score at each point threshold for PSH projects' do
      report.update!(project_type: 3, psh_stayers_or_to_ph: 75)
      expect(report.psh_stayers_or_to_ph_score).to eq(12)

      report.update!(psh_stayers_or_to_ph: 55)
      expect(report.psh_stayers_or_to_ph_score).to eq(6)

      report.update!(psh_stayers_or_to_ph: 25)
      expect(report.psh_stayers_or_to_ph_score).to eq(4)

      report.update!(psh_stayers_or_to_ph: 24)
      expect(report.psh_stayers_or_to_ph_score).to eq(0)
    end

    it 'awards returns_to_homelessness_score at each point threshold (lower is better)' do
      report.update!(returns_to_homelessness: 5)
      expect(report.returns_to_homelessness_score).to eq(12)

      report.update!(returns_to_homelessness: 25)
      expect(report.returns_to_homelessness_score).to eq(6)

      report.update!(returns_to_homelessness: 50)
      expect(report.returns_to_homelessness_score).to eq(4)

      report.update!(returns_to_homelessness: 51)
      expect(report.returns_to_homelessness_score).to eq(0)
    end

    it 'awards increased_employment_income_score at each point threshold' do
      report.update!(increased_employment_income: 20)
      expect(report.increased_employment_income_score).to eq(12)

      report.update!(increased_employment_income: 15)
      expect(report.increased_employment_income_score).to eq(6)

      report.update!(increased_employment_income: 7)
      expect(report.increased_employment_income_score).to eq(4)

      report.update!(increased_employment_income: 6)
      expect(report.increased_employment_income_score).to eq(0)
    end

    it 'awards increased_other_income_score at each point threshold' do
      report.update!(increased_other_income: 50)
      expect(report.increased_other_income_score).to eq(12)

      report.update!(increased_other_income: 37)
      expect(report.increased_other_income_score).to eq(6)

      report.update!(increased_other_income: 17)
      expect(report.increased_other_income_score).to eq(4)

      report.update!(increased_other_income: 16)
      expect(report.increased_other_income_score).to eq(0)
    end

    it 'awards 0 for days_to_lease_up_score when current year is less than 1 day' do
      report.update!(days_to_lease_up: 0, days_to_lease_up_comparison: nil)
      expect(report.days_to_lease_up_score).to eq(0)

      report.update!(days_to_lease_up: 0, days_to_lease_up_comparison: 0)
      expect(report.days_to_lease_up_score).to eq(0)

      report.update!(days_to_lease_up: 0, days_to_lease_up_comparison: 100)
      expect(report.days_to_lease_up_score).to eq(0)
    end

    it 'awards days_to_lease_up_score based on absolute days when there is no comparison' do
      report.update!(days_to_lease_up: 89, days_to_lease_up_comparison: nil)
      expect(report.days_to_lease_up_score).to eq(12)

      report.update!(days_to_lease_up: 90, days_to_lease_up_comparison: nil)
      expect(report.days_to_lease_up_score).to eq(0)
    end

    it 'awards 12 pts when current FY is under 90 days even if it is an increase from prior FY' do
      report.update!(days_to_lease_up: 85, days_to_lease_up_comparison: 10)
      expect(report.days_to_lease_up_score).to eq(12)
    end

    it 'awards days_to_lease_up_score based on year-over-year improvement once over 90 days' do
      report.update!(days_to_lease_up: 100, days_to_lease_up_comparison: 200) # -50% change
      expect(report.days_to_lease_up_score).to eq(12)

      report.update!(days_to_lease_up: 100, days_to_lease_up_comparison: 105) # -5% change, exactly at threshold
      expect(report.days_to_lease_up_score).to eq(12)

      report.update!(days_to_lease_up: 100, days_to_lease_up_comparison: 104) # ~-3.8% change
      expect(report.days_to_lease_up_score).to eq(6)

      report.update!(days_to_lease_up: 100, days_to_lease_up_comparison: 101) # ~-1% change
      expect(report.days_to_lease_up_score).to eq(6)

      report.update!(days_to_lease_up: 100, days_to_lease_up_comparison: 100) # no change
      expect(report.days_to_lease_up_score).to eq(0)

      report.update!(days_to_lease_up: 100, days_to_lease_up_comparison: 90) # increase
      expect(report.days_to_lease_up_score).to eq(0)
    end

    it 'awards data quality scores at the 20% error threshold, per metric' do
      report.update!(pii_error_rate: 20)
      expect(report.pii_error_rate_score).to eq(5)

      report.update!(pii_error_rate: 21)
      expect(report.pii_error_rate_score).to eq(0)

      # ude and income/housing error rates share the same threshold logic;
      # confirm each reads its own field rather than pii_error_rate
      report.update!(ude_error_rate: 20, income_and_housing_error_rate: 21)
      expect(report.ude_error_rate_score).to eq(5)
      expect(report.income_and_housing_error_rate_score).to eq(0)
    end
  end

  describe '#send_email_to_secondary_reviewer' do
    after { clear_enqueued_jobs }

    context 'when secondary_reviewer is not set' do
      it 'does not enqueue an email, and does not raise when the queue is worked off' do
        expect(report.secondary_reviewer).to be_nil

        expect { report.send_email_to_secondary_reviewer }.not_to have_enqueued_job

        expect { perform_enqueued_jobs }.not_to raise_error
      end
    end

    context 'when secondary_reviewer is set' do
      let(:secondary_reviewer) { create :user }

      it 'enqueues and delivers an email to the secondary reviewer' do
        expect do
          perform_enqueued_jobs { report.send_email_to_secondary_reviewer }
        end.to change(Message, :count).by(1)

        expect(Message.last.user_id).to eq(secondary_reviewer.id)
      end
    end
  end

  describe '#include_gender_data? and #pii_error_cell' do
    it 'includes gender data, and reads the PII error rate from F7, for pre-FY2026 generators' do
      allow(report).to receive(:apr_generator).and_return(HudApr::Generators::Apr::Fy2024::Generator)

      expect(report.include_gender_data?).to eq(true)
      expect(report.pii_error_cell).to eq('F7')
    end

    it 'excludes gender data, and reads the PII error rate from F6, once gender data is removed from the APR (FY2026+)' do
      allow(report).to receive(:apr_generator).and_return(HudApr::Generators::Apr::Fy2026::Generator)

      expect(report.include_gender_data?).to eq(false)
      expect(report.pii_error_cell).to eq('F6')
    end
  end

  describe '#locked?' do
    before { report.update!(status: 'pending') }

    it 'leaves header fields editable while pending, but locks everything else' do
      expect(report.locked?(:period_start_date, user)).to eq(false)
      expect(report.locked?(:secondary_reviewer_id, user)).to eq(false)
      expect(report.locked?(:no_concern, user)).to eq(true)
    end

    it 'unlocks the entire form once pre-filled' do
      report.update!(status: 'pre-filled')

      expect(report.locked?(:period_start_date, user)).to eq(false)
      expect(report.locked?(:no_concern, user)).to eq(false)
    end

    it 'locks header fields once ready, leaving the rest editable' do
      report.update!(status: 'ready')

      expect(report.locked?(:period_start_date, user)).to eq(true)
      expect(report.locked?(:no_concern, user)).to eq(false)
    end

    it 'locks every field for any other status' do
      report.update!(status: 'completed')

      expect(report.locked?(:period_start_date, user)).to eq(true)
      expect(report.locked?(:no_concern, user)).to eq(true)
    end
  end

  describe '#field_input_options' do
    it 'marks locked fields readonly, and leaves unlocked fields alone' do
      report.update!(status: 'ready')

      expect(report.field_input_options(:project_type, user)).to eq(readonly: true)
      expect(report.field_input_options(:no_concern, user)).to eq({})
    end
  end

  describe '#apr_report' do
    before { project_coc }

    it 'scopes the real APR filter to the report project, independent of the mocked answer data used elsewhere in this file' do
      allow(Reporting::Hud::RunReportJob).to receive(:perform_now) do |_class_name, report_id, **_kwargs|
        HudReports::ReportInstance.find(report_id).update!(state: 'Completed', completed_at: Time.current)
      end

      apr = report.send(:apr_report)

      expect(apr.project_ids).to eq([project.id])
      expect(apr).to be_completed
    end
  end
end
