# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../hud_spm_report/spec/models/fy2024/shared_context'

RSpec.describe 'Performance Measurement and SPM Alignment', type: :model do
  include_context 'SPM test setup'

  # Common variables
  let(:test_start_date) { '2022-10-01'.to_date }
  let(:test_end_date) { '2023-09-30'.to_date }
  let(:test_coc_code) { 'MA-500' }

  # Shared setup for report generation
  let(:default_filter) do
    Filters::HudFilterBase.new(
      user_id: user.id,
      start: test_start_date,
      end: test_end_date,
      coc_codes: [test_coc_code],
      enforce_one_year_range: false,
    )
  end

  # Helper method for comparing SPM and PM values consistently
  def compare_spm_and_pm_values(spm_value, pm_value)
    # Format values for output in case of failure
    formatted_spm = "#{spm_value} (#{spm_value.class})"
    formatted_pm = "#{pm_value} (#{pm_value.class})"

    # Convert to appropriate numeric type if needed
    spm_value = spm_value.to_f if spm_value.is_a?(String)
    pm_value = pm_value.to_f if pm_value.is_a?(String)
    expect(spm_value).to be > 0

    # For counts or values that should match exactly
    rounded_spm = spm_value.round
    rounded_pm = pm_value.round

    expect(rounded_pm).to eq(rounded_spm), "Original values: SPM=#{formatted_spm}, PM=#{formatted_pm}"
  end

  # Method to create and run both reports
  def setup_reports(projects:)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    # Create PM report
    PerformanceMeasurement::Goal.ensure_default
    pm_report = PerformanceMeasurement::Report.new(user_id: user.id)
    pm_report.filter = default_filter.dup
    pm_report.filter.update(project_ids: projects.map(&:id))
    pm_report.update_goal_configuration!
    pm_report.save!
    pm_report.run_and_save!
    pm_report.reload
    spm_report = HudReports::ReportInstance.find(pm_report.reporting_spm_id)
    [spm_report, pm_report]
  end

  describe 'measure 1 values alignment' do
    before do
      # Create projects
      @es_project = create_project(project_type: 0) # ES-EE
      @es_nbn_project = create_project(project_type: 1) # ES-NbN
      @th_project = create_project(project_type: 2) # TH

      # Create clients with different homeless patterns
      @client1 = create_client_with_warehouse_link
      @client2 = create_client_with_warehouse_link
      @client3 = create_client_with_warehouse_link

      # Client 1: Simple ES stay (75 days)
      create_enrollment(
        client: @client1,
        project: @es_project,
        entry_date: test_start_date + 30.days,
        exit_date: test_start_date + 105.days,
      )

      # Client 2: ES stay followed by TH stay with gap
      create_enrollment(
        client: @client2,
        project: @es_project,
        entry_date: test_start_date + 15.days,
        exit_date: test_start_date + 75.days,
      )

      create_enrollment(
        client: @client2,
        project: @th_project,
        entry_date: test_start_date + 80.days,
        exit_date: test_start_date + 110.days,
      )

      # Client 3: Overlapping ES NbN stays
      enrollment = create_enrollment(
        client: @client3,
        project: @es_nbn_project,
        entry_date: test_start_date + 1.day,
        exit_date: test_start_date + 60.days,
      )

      # Add bed nights for night-by-night shelter
      (test_start_date + 1.day..test_start_date + 60.days).each do |date|
        create_bed_night_service(enrollment: enrollment, date: date)
      end

      # Create another ES enrollment with explicit date_to_street_essh for self-reported data
      create_enrollment(
        client: @client3,
        project: @es_project,
        entry_date: test_start_date + 70.days,
        exit_date: test_start_date + 120.days,
        date_to_street_essh: test_start_date + 50.days, # Self-reported homelessness start date
      )

      @spm_report, @pm_report = setup_reports(projects: [@es_project, @es_nbn_project, @th_project])
    end

    it 'has the same average length of time homeless in both reports' do
      # SPM report average LOT homeless
      spm_average = @spm_report.answer(question: '1a', cell: 'D2').summary

      # PM report average LOT homeless
      pm_result = @pm_report.result_for(:length_of_homeless_time_homeless_average)
      pm_average = pm_result.primary_value

      compare_spm_and_pm_values(spm_average, pm_average)
    end

    it 'has the same median length of time homeless in both reports' do
      # SPM report median LOT homeless
      spm_median = @spm_report.answer(question: '1a', cell: 'G2').summary

      # PM report median LOT homeless
      pm_result = @pm_report.result_for(:length_of_homeless_time_homeless_median)
      pm_median = pm_result.primary_value

      compare_spm_and_pm_values(spm_median, pm_median)
    end

    it 'has the same client count in both reports' do
      # SPM report universe count
      spm_client_count = @spm_report.answer(question: '1a', cell: 'B2').summary

      # PM report client count
      pm_client_count = @pm_report.clients.count

      # Both should have 3 clients
      expect(pm_client_count).to eq(spm_client_count.to_i)
    end
  end

  describe 'measure 2 values alignment' do
    before do
      # Create projects
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PH

      # Create clients with different return patterns
      @client1 = create_client_with_warehouse_link
      @client2 = create_client_with_warehouse_link
      @client3 = create_client_with_warehouse_link

      # For SPM Measure 2, we need to create exits from two years ago
      # and then returns within the reporting period

      # Client 1: Exit to PH then returns to ES within 6 months
      create_enrollment(
        client: @client1,
        project: @ph_project,
        entry_date: test_start_date - 600.days,
        exit_date: test_start_date - 550.days,
        destination: 410, # Rental by client, no subsidy (permanent)
      )

      create_enrollment(
        client: @client1,
        project: @es_project,
        entry_date: test_start_date - 500.days, # Within 6 months of exit
        exit_date: test_start_date - 480.days,
      )

      # Client 2: Exit to PH then returns to ES within 12 months (but after 6 months)
      create_enrollment(
        client: @client2,
        project: @ph_project,
        entry_date: test_start_date - 600.days,
        exit_date: test_start_date - 550.days,
        destination: 410, # Rental by client, no subsidy (permanent)
      )

      create_enrollment(
        client: @client2,
        project: @es_project,
        entry_date: test_start_date - 370.days, # Between 6-12 months after exit
        exit_date: test_start_date - 350.days,
      )

      # Client 3: Exit to PH and doesn't return
      create_enrollment(
        client: @client3,
        project: @ph_project,
        entry_date: test_start_date - 600.days,
        exit_date: test_start_date - 550.days,
        destination: 410, # Rental by client, no subsidy (permanent)
      )

      @spm_report, @pm_report = setup_reports(projects: [@es_project, @ph_project])
    end

    it 'has the same 6-month return rate in both reports' do
      # SPM report 6-month return percentage
      spm_percentage = @spm_report.answer(question: '2a and 2b', cell: 'D7').summary

      # PM report 6-month return rate
      pm_result = @pm_report.result_for(:returned_in_six_months)
      pm_percentage = pm_result.primary_value

      compare_spm_and_pm_values(spm_percentage, pm_percentage)
    end

    it 'has the same 24-month return rate in both reports' do
      # SPM report 24-month return percentage
      spm_percentage = @spm_report.answer(question: '2a and 2b', cell: 'J7').summary

      # PM report 24-month return rate
      pm_result = @pm_report.result_for(:returned_in_two_years)
      pm_percentage = pm_result.primary_value

      compare_spm_and_pm_values(spm_percentage, pm_percentage)
    end

    it 'has the same count of total exits to permanent housing' do
      # SPM report total exits to permanent housing
      spm_count = @spm_report.answer(question: '2a and 2b', cell: 'B7').summary

      # PM report denominator for returns calculation
      pm_result = @pm_report.result_for(:returned_in_two_years)
      pm_count = pm_result.reporting_denominator

      expect(pm_count).to eq(spm_count.to_i)
    end
  end

  describe 'measure 3 values alignment' do
    before do
      # Create projects
      @es_project = create_project(project_type: 0) # ES-EE
      @so_project = create_project(project_type: 4) # SO

      # Create multiple clients for more robust testing
      @client1 = create_client_with_warehouse_link
      @client2 = create_client_with_warehouse_link
      @client3 = create_client_with_warehouse_link

      # Client 1: ES enrollment during the report period
      create_enrollment(
        client: @client1,
        project: @es_project,
        entry_date: test_start_date + 60.days,
        exit_date: test_start_date + 120.days,
      )

      # Client 2: ES enrollment that spans the report period
      create_enrollment(
        client: @client2,
        project: @es_project,
        entry_date: test_start_date - 30.days,
        exit_date: test_start_date + 30.days,
      )

      # Client 3: SO enrollment for unsheltered count
      create_enrollment(
        client: @client3,
        project: @so_project,
        entry_date: test_start_date + 90.days,
        exit_date: test_start_date + 150.days,
      )

      @spm_report, @pm_report = setup_reports(projects: [@es_project, @so_project])
    end

    it 'has the same count of homeless clients in both reports' do
      # SPM report total sheltered homeless count
      spm_count = @spm_report.answer(question: '3.2', cell: 'C2').summary

      # PM report homeless count
      pm_result = @pm_report.result_for(:count_of_homeless_clients_in_range)
      pm_count = pm_result.primary_value

      compare_spm_and_pm_values(spm_count, pm_count)
    end

    it 'has the same count of sheltered homeless clients' do
      # SPM report sheltered count
      spm_count = @spm_report.answer(question: '3.2', cell: 'C3').summary

      # PM report sheltered count
      pm_result = @pm_report.result_for(:count_of_sheltered_homeless_clients)
      pm_count = pm_result.primary_value

      compare_spm_and_pm_values(spm_count, pm_count)
    end
  end

  describe 'measure 4 values alignment' do
    before do
      # Create projects with CoC funding
      @psh_project = create_project(project_type: 3)
      create(:hud_funder, project: @psh_project, funder: 2, data_source: data_source)

      # Create clients
      @client1 = create_client_with_warehouse_link # Stayer with income increase
      @client2 = create_client_with_warehouse_link # Leaver with income increase
      @client3 = create_client_with_warehouse_link # Stayer with no income change

      # Client 1: Stayer with income increase
      enrollment1 = create_enrollment(
        client: @client1,
        project: @psh_project,
        entry_date: test_start_date - 400.days,
        exit_date: nil, # still active
      )

      # Entry income for client 1
      create(
        :hud_income_benefit,
        enrollment: enrollment1,
        data_source: data_source,
        information_date: enrollment1.entry_date,
        data_collection_stage: 1, # Entry
        earned: 1,
        earned_amount: 500,
      )

      # Annual assessment for client 1
      create(
        :hud_income_benefit,
        enrollment: enrollment1,
        data_source: data_source,
        information_date: enrollment1.entry_date + 365.days, # Annual assessment
        data_collection_stage: 5, # Annual
        earned: 1,
        earned_amount: 1000, # Increased
      )

      # Client 2: Leaver with income increase
      enrollment2 = create_enrollment(
        client: @client2,
        project: @psh_project,
        entry_date: test_start_date - 200.days,
        exit_date: test_start_date + 100.days,
      )

      # Entry income for client 2
      create(
        :hud_income_benefit,
        enrollment: enrollment2,
        data_source: data_source,
        information_date: enrollment2.entry_date,
        data_collection_stage: 1, # Entry
        earned: 1,
        earned_amount: 800,
      )

      # Exit income for client 2
      create(
        :hud_income_benefit,
        enrollment: enrollment2,
        data_source: data_source,
        information_date: enrollment2.exit.exit_date,
        data_collection_stage: 3, # Exit
        earned: 1,
        earned_amount: 1200, # Increased
      )

      # Client 3: Stayer with no income change
      enrollment3 = create_enrollment(
        client: @client3,
        project: @psh_project,
        entry_date: test_start_date - 400.days,
        exit_date: nil, # still active
      )

      # Entry income for client 3
      create(
        :hud_income_benefit,
        enrollment: enrollment3,
        data_source: data_source,
        information_date: enrollment3.entry_date,
        data_collection_stage: 1, # Entry
        earned: 1,
        earned_amount: 700,
      )

      # Annual assessment for client 3 (same income)
      create(
        :hud_income_benefit,
        enrollment: enrollment3,
        data_source: data_source,
        information_date: enrollment3.entry_date + 365.days, # Annual assessment
        data_collection_stage: 5, # Annual
        earned: 1,
        earned_amount: 700, # No change
      )

      @spm_report, @pm_report = setup_reports(projects: [@psh_project])
    end

    it 'has the same rate of income increase for stayers in both reports' do
      # SPM report income increase percentage for stayers
      spm_percentage = @spm_report.answer(question: '4.3', cell: 'C4').summary

      # PM report income increase for stayers
      pm_result = @pm_report.result_for(:stayers_with_increased_income)
      pm_percentage = pm_result.primary_value

      compare_spm_and_pm_values(spm_percentage, pm_percentage)
    end

    it 'has the same rate of income increase for leavers in both reports' do
      # SPM report income increase percentage for leavers
      spm_percentage = @spm_report.answer(question: '4.6', cell: 'C4').summary

      # PM report income increase for leavers
      pm_result = @pm_report.result_for(:leavers_with_increased_income)
      pm_percentage = pm_result.primary_value

      compare_spm_and_pm_values(spm_percentage, pm_percentage)
    end

    it 'has the same count of stayers' do
      # SPM report count of stayers
      spm_count = @spm_report.answer(question: '4.3', cell: 'C2').summary

      # PM report count from stayers result
      pm_result = @pm_report.result_for(:stayers_with_increased_income)
      pm_count = pm_result.reporting_denominator

      expect(pm_count).to eq(spm_count.to_i)
    end
  end

  describe 'measure 5 values alignment' do
    before do
      # Create projects
      @es_project = create_project(project_type: 0) # ES-EE
      @th_project = create_project(project_type: 2) # TH
      @ph_project = create_project(project_type: 3) # PH

      # Create clients with varied history
      @client1 = create_client_with_warehouse_link # First-time homeless
      @client2 = create_client_with_warehouse_link # First-time homeless in PH
      @client3 = create_client_with_warehouse_link # Not first-time homeless

      # Client 3: Create a historical enrollment before the lookback
      create_enrollment(
        client: @client3,
        project: @es_project,
        entry_date: test_start_date - 800.days,
        exit_date: test_start_date - 770.days,
      )

      # Client 1: First-time homeless in ES
      create_enrollment(
        client: @client1,
        project: @es_project,
        entry_date: test_start_date + 90.days,
        exit_date: test_start_date + 120.days,
      )

      # Client 2: First-time homeless in PH
      create_enrollment(
        client: @client2,
        project: @ph_project,
        entry_date: test_start_date + 60.days,
        exit_date: test_start_date + 180.days,
      )

      # Client 3: Current enrollment (not first-time)
      create_enrollment(
        client: @client3,
        project: @th_project,
        entry_date: test_start_date + 30.days,
        exit_date: test_start_date + 60.days,
      )

      @spm_report, @pm_report = setup_reports(projects: [@es_project, @th_project, @ph_project])
    end

    it 'has the same first-time homeless count in both reports for ES, SH, TH' do
      # SPM report first-time homeless in ES, SH, TH
      spm_count = @spm_report.answer(question: '5.1', cell: 'C4').summary

      # PM report first-time homeless
      pm_result = @pm_report.result_for(:first_time_homeless_clients)
      pm_count = pm_result.primary_value

      compare_spm_and_pm_values(spm_count, pm_count)
    end

    it 'counts the same total entries in the reporting period' do
      # SPM report total universe
      spm_count = @spm_report.answer(question: '5.1', cell: 'C2').summary

      # Count from PM report
      # This may need adjustment depending on exactly how PM tracks this
      pm_count = @pm_report.clients.where.not('reporting_first_time' => nil).count

      expect(pm_count).to be > 0
      expect(pm_count).to eq(spm_count.to_i)
    end
  end

  describe 'measure 7 values alignment' do
    before do
      # Create projects of different types
      @es_project = create_project(project_type: 0) # ES-EE
      @th_project = create_project(project_type: 2) # TH
      @rrh_project = create_project(project_type: 13) # RRH
      @psh_project = create_project(project_type: 3) # PSH
      @so_project = create_project(project_type: 4) # SO

      # Create clients with different exit scenarios
      @client1 = create_client_with_warehouse_link # SO exit to temporary
      @client2 = create_client_with_warehouse_link # ES exit to permanent
      @client3 = create_client_with_warehouse_link # PH stayer with move-in
      @client4 = create_client_with_warehouse_link # RRH with move-in and exit to permanent

      # Client 1: Exit from SO to temporary destination
      create_enrollment(
        client: @client1,
        project: @so_project,
        entry_date: test_start_date + 30.days,
        exit_date: test_start_date + 60.days,
        destination: 302, # Transitional housing (temporary)
      )

      # Client 2: Exit from ES to permanent housing
      create_enrollment(
        client: @client2,
        project: @es_project,
        entry_date: test_start_date + 45.days,
        exit_date: test_start_date + 90.days,
        destination: 410, # Rental by client, no subsidy (permanent)
      )

      # Client 3: PH stayer with move-in date
      create_enrollment(
        client: @client3,
        project: @psh_project,
        entry_date: test_start_date + 15.days,
        exit_date: nil, # Still in program
        move_in_date: test_start_date + 45.days,
      )

      # Client 4: RRH exit to permanent housing after move-in
      create_enrollment(
        client: @client4,
        project: @rrh_project,
        entry_date: test_start_date + 20.days,
        exit_date: test_start_date + 150.days,
        move_in_date: test_start_date + 50.days,
        destination: 410, # Rental by client, no subsidy (permanent)
      )

      @spm_report, @pm_report = setup_reports(projects: [@es_project, @th_project, @rrh_project, @psh_project, @so_project])
    end

    it 'has the same successful SO placement rate in both reports' do
      # SPM report successful placement percentage for SO
      spm_percentage = @spm_report.answer(question: '7a.1', cell: 'C5').summary

      # PM report success rate for SO
      pm_result = @pm_report.result_for(:so_positive_destinations)
      pm_percentage = pm_result.primary_value

      compare_spm_and_pm_values(spm_percentage, pm_percentage)
    end

    it 'has the same permanent housing exit rate for ES, SH, TH, RRH in both reports' do
      # SPM report successful placement percentage for ES/SH/TH/RRH exits
      spm_percentage = @spm_report.answer(question: '7b.1', cell: 'C4').summary

      # PM report success rate
      pm_result = @pm_report.result_for(:es_sh_th_rrh_positive_destinations)
      pm_percentage = pm_result.primary_value

      compare_spm_and_pm_values(spm_percentage, pm_percentage)
    end

    it 'has the same PH retention or exit rate in both reports' do
      # SPM report retention percentage for PH projects
      spm_percentage = @spm_report.answer(question: '7b.2', cell: 'C4').summary

      # PM report retention rate
      pm_result = @pm_report.result_for(:moved_in_positive_destinations)
      pm_percentage = pm_result.primary_value

      compare_spm_and_pm_values(spm_percentage, pm_percentage)
    end

    it 'has the same exit count for ES, SH, TH, RRH in both reports' do
      # SPM report count of exits
      spm_count = @spm_report.answer(question: '7b.1', cell: 'C2').summary

      # PM report count
      pm_result = @pm_report.result_for(:es_sh_th_rrh_positive_destinations)
      pm_count = pm_result.reporting_denominator

      expect(pm_count).to eq(spm_count.to_i)
    end
  end
end
