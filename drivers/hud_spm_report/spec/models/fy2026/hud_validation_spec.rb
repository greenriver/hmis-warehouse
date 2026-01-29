###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe 'SPM Measure 1 HUD Validation Cases', type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

  describe 'Measure 1a HUD Test Cases' do
    # 1. Total Negation
    it 'Total Negation: excludes client when all shelter nights are negated by PH Housing Move-In Date' do
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PSH
      @client = create_client_with_warehouse_link

      # Shelter stay: 2022-11-01 to 2022-11-10 (9 nights: 1st through 9th)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-11-10'.to_date,
      )

      # PH stay negating all shelter nights: Move-In on or before shelter entry
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-10-01'.to_date,
        move_in_date: '2022-10-15'.to_date, # Housed before shelter entry
        exit_date: '2022-12-01'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      expect(@report.universe('m1a1').members.count).to eq(0)
    end

    # 2. Exit vs. Move-In (Same Day)
    it 'Exit vs. Move-In (Same Day): shelter bed nights are unaffected when exit date equals move-in date' do
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PSH
      @client = create_client_with_warehouse_link

      # Shelter stay: 2022-11-01 to 2022-11-10
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-11-10'.to_date,
      )

      # PH move-in on shelter exit date
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-11-10'.to_date,
        move_in_date: '2022-11-10'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      # Expected: 2022-11-01 to 2022-11-09 = 9 days
      expect(episode.days_homeless).to eq(9)
      expect(episode.last_date).to eq('2022-11-09'.to_date)
    end

    # 3. Overlap (1 Day)
    it 'Overlap (1 Day): shelter exit date is effectively back-dated by one day when it is after move-in date' do
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PSH
      @client = create_client_with_warehouse_link

      # Shelter stay exit is one day AFTER PH move-in
      # ES: 2022-11-01 to 2022-11-11 (Normally 1st-10th = 10 nights)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-11-11'.to_date,
      )

      # PH move-in on 2022-11-10
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-11-10'.to_date,
        move_in_date: '2022-11-10'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      # Expected: 2022-11-01 to 2022-11-09 = 9 days (10th is negated)
      expect(episode.days_homeless).to eq(9)
      expect(episode.last_date).to eq('2022-11-09'.to_date)
    end

    # 4. Start vs. PH Exit (1 Day Gap)
    it 'Start vs. PH Exit (1 Day Gap): shelter start date is bumped forward when it is before PH exit while housed' do
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PSH
      @client = create_client_with_warehouse_link

      # PH stay: client already housed, exits 2022-11-05
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-10-01'.to_date,
        move_in_date: '2022-10-15'.to_date,
        exit_date: '2022-11-05'.to_date,
      )

      # Shelter start is one day PRIOR to PH exit (2022-11-04)
      # ES: 2022-11-04 to 2022-11-15
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-04'.to_date,
        exit_date: '2022-11-15'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      # Expected: Shelter start bumped from 4th to 5th.
      # nights: 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 = 10 days
      expect(episode.first_date).to eq('2022-11-05'.to_date)
      expect(episode.days_homeless).to eq(10)
    end

    # 5. Start vs. PH Exit (Same Day)
    it 'Start vs. PH Exit (Same Day): shelter start date remains unaffected when it equals PH exit date' do
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PSH
      @client = create_client_with_warehouse_link

      # PH stay: client already housed, exits 2022-11-05
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-10-01'.to_date,
        move_in_date: '2022-10-15'.to_date,
        exit_date: '2022-11-05'.to_date,
      )

      # Shelter start is SAME day as PH exit (2022-11-05)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-05'.to_date,
        exit_date: '2022-11-15'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      # Expected: Shelter start remains 5th.
      # nights: 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 = 10 days
      expect(episode.first_date).to eq('2022-11-05'.to_date)
      expect(episode.days_homeless).to eq(10)
    end

    # 10. PH move-in date before project start (Discarded)
    it 'Discard move-in date before project start' do
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PSH
      @client = create_client_with_warehouse_link

      # ES: 2022-11-01 to 2022-11-15
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-11-15'.to_date,
      )

      # PH: Entry 11/05, Move-In 11/01 (Invalid, before entry)
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-11-05'.to_date,
        move_in_date: '2022-11-01'.to_date,
        exit_date: '2022-11-15'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      # If move-in date 11/01 is discarded, no negation happens.
      # Expected: 14 days
      expect(episode.days_homeless).to eq(14)
    end

    it 'Contiguous nights: expansion stops at a gap of 1 or more days when before client start date' do
      @es_project = create_project(project_type: 0) # ES-EE
      @client = create_client_with_warehouse_link

      # client_end_date will be 2023-09-30
      # client_start_date will be 2022-09-30

      # Stay 1: 2022-01-01 to 2022-01-10 (bed nights: 01/01-01/09)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-01'.to_date,
        exit_date: '2022-01-10'.to_date,
      )

      # GAP: 2022-01-10 (1 day missing) - breaks contiguity

      # Stay 2: 2022-01-11 to 2022-01-21 (bed nights: 01/11-01/20)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-11'.to_date,
        exit_date: '2022-01-21'.to_date,
      )

      # NO GAP: Stay 2 last bed night is 01/20, Stay 3 first bed night is 01/21
      # 01/20 is exactly one day earlier than 01/21 - CONTIGUOUS

      # Stay 3: 2022-01-21 to 2023-10-01 (bed nights: 01/21-09/30)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-21'.to_date,
        exit_date: '2023-10-01'.to_date,
      )

      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership

      # client_end_date is 2023-09-30 (report end)
      # client_start_date is 2022-09-30
      # Stay 3 starts 2022-01-21, which is before client_start_date
      # Expansion works backward from client_start_date
      # Stay 3 is contiguous back to 01/21
      # Stay 2 ends 01/20, which is exactly 1 day before 01/21 - CONTIGUOUS
      # Stay 2 is contiguous back to 01/11
      # Stay 1 ends 01/09, which is 2 days before 01/11 (01/10 missing) - NOT CONTIGUOUS
      # Expansion stops at 01/11

      expect(episode.first_date).to eq('2022-01-11'.to_date)
    end
  end

  describe 'Median Calculation HUD Specs' do
    it 'correctly calculates median for odd number of clients' do
      @es_project = create_project(project_type: 0)

      # 3 clients with LOT: 10, 20, 30
      [10, 20, 30].each_with_index do |days, i|
        client = create_client_with_warehouse_link(uid: "P#{i}")
        create_enrollment(
          client: client,
          project: @es_project,
          entry_date: '2023-01-01'.to_date,
          exit_date: ('2023-01-01'.to_date + days.days),
        )
      end

      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      # Median of [10, 20, 30] is 20
      answer = @report.answer(question: '1a', cell: 'G2')
      expect(answer.summary.to_f).to eq(20.0)
    end

    it 'correctly calculates median for even number of clients' do
      @es_project = create_project(project_type: 0)

      # 4 clients with LOT: 10, 20, 30, 40
      [10, 20, 30, 40].each_with_index do |days, i|
        client = create_client_with_warehouse_link(uid: "P#{i}")
        create_enrollment(
          client: client,
          project: @es_project,
          entry_date: '2023-01-01'.to_date,
          exit_date: ('2023-01-01'.to_date + days.days),
        )
      end

      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      # Median of [10, 20, 30, 40] is (20 + 30) / 2 = 25.0
      answer = @report.answer(question: '1a', cell: 'G2')
      expect(answer.summary.to_f).to eq(25.0)
    end
  end

  describe 'Measure 1b HUD Test Cases' do
    # Scenario: Back-dating with 3.917.3 and PH Breaks
    it 'Measure 1b: PH stay creates a break in homelessness, stopping backward expansion' do
      @es_project = create_project(project_type: 0) # ES-EE
      @ph_project = create_project(project_type: 3) # PSH
      @client = create_client_with_warehouse_link

      # Shelter start: 6/1/2023
      # 3.917.3 (Approximate date this episode started): 3/1/2023
      shelter_start = '2023-06-01'.to_date
      approx_start = '2023-03-01'.to_date # 92 days back-dated

      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: shelter_start,
        exit_date: '2023-06-15'.to_date,
        date_to_street_essh: approx_start,
      )

      # PH stay: exits 30 days before shelter start = 2023-05-02
      # Client was already housed.
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2023-01-01'.to_date,
        move_in_date: '2023-02-01'.to_date,
        exit_date: '2023-05-02'.to_date,
      )

      # Another shelter stay BEFORE the PH stay - should be EXCLUDED due to break
      # client_end_date is June 2023, so client_start_date is June 2022.
      # Let's put this stay in Jan 2022 (outside the 365-day window).
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-01'.to_date,
        exit_date: '2022-02-01'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1b1').members.first.universe_membership

      # If PH stay creates a break, first_date should be 2023-05-02
      expect(episode.first_date).to eq('2023-05-02'.to_date)
      # Total days homeless = 30 (pre-entry) + 14 (shelter) = 44.
      expect(episode.days_homeless).to eq(44)
    end

    it 'Measure 1b: excludes PH stays that are NOT literally homeless at entry' do
      @ph_project = create_project(project_type: 3) # PH-PSH
      @client = create_client_with_warehouse_link

      # Create PH enrollment that is NOT literally homeless at entry
      # Entry from Rental by Client (Code 435) without meeting the additional criteria
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2023-01-01'.to_date,
        exit_date: nil, # Still active, no housing move-in yet
        living_situation: 435, # Rental by client - in range 300:499
        los_under_threshold: 0, # Did NOT stay less than 7 nights
        previous_street_essh: 0, # Did NOT come from streets/ES/SH the night before
      )

      @report = setup_report([@ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      # PH clients who are not literally homeless at entry should be excluded from Measure 1b
      expect(@report.universe('m1b1').members.count).to eq(0)
      expect(@report.universe('m1b2').members.count).to eq(0)
    end

    it 'Measure 1b: includes PH stays that ARE literally homeless at entry' do
      @ph_project = create_project(project_type: 3) # PH-PSH
      @client = create_client_with_warehouse_link

      # Create PH enrollment that IS literally homeless at entry
      # Entry from Emergency Shelter (Code 101) - in range 100:199
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2023-01-01'.to_date,
        exit_date: nil, # Still active, no housing move-in yet
        move_in_date: nil,
        living_situation: 101, # Emergency shelter - literally homeless
      )

      @report = setup_report([@ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      # PH clients who are literally homeless at entry should be included in Measure 1b
      expect(@report.universe('m1b1').members.count).to eq(1)
      expect(@report.universe('m1b2').members.count).to eq(1)
    end

    it 'Measure 1b: includes TH stays regardless of living situation at entry' do
      @th_project = create_project(project_type: 2) # TH
      @client = create_client_with_warehouse_link

      # Create TH enrollment with non-homeless prior living situation
      # TH clients are included in the base universe without the literal homelessness check
      create_enrollment(
        client: @client,
        project: @th_project,
        entry_date: '2023-01-01'.to_date,
        exit_date: '2023-02-01'.to_date,
        living_situation: 435, # Rental by client - doesn't matter for TH
      )

      @report = setup_report([@th_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      # TH clients are included in Measure 1b regardless of prior living situation
      # They appear in metric 2 (which includes TH) but not metric 1 (which excludes TH)
      expect(@report.universe('m1b1').members.count).to eq(0) # m1b1 excludes TH
      expect(@report.universe('m1b2').members.count).to eq(1) # m1b2 includes TH
    end

    it 'Measure 1b Metric 2: includes TH stayers who were literally homeless at entry' do
      @th_project = create_project(project_type: 2) # TH
      @client = create_client_with_warehouse_link

      # TH stayer: started 2022-01-01, active during report range (2022-10-01 to 2023-09-30)
      # Literally homeless at entry (Living Situation 101)
      create_enrollment(
        client: @client,
        project: @th_project,
        entry_date: '2022-01-01'.to_date,
        living_situation: 101,
      )

      @report = setup_report([@th_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      # Metric 2 (m1b2) should include this client.
      expect(@report.universe('m1b2').members.count).to eq(1)
    end
  end
end
