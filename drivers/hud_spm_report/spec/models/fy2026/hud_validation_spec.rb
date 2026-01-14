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

    # 6. Zero-Night Stay
    it 'Zero-Night Stay: shelter stay with same start and exit date is excluded' do
      @es_project = create_project(project_type: 0) # ES-EE
      @client = create_client_with_warehouse_link

      # Shelter stay: 2022-11-05 to 2022-11-05
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-05'.to_date,
        exit_date: '2022-11-05'.to_date,
      )

      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      expect(@report.universe('m1a1').members.count).to eq(0)
    end

    # 7. PH with no move-in date
    it 'PH with no move-in date does not negate shelter nights' do
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

      # PH stay without Move-In date
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-10-01'.to_date,
        move_in_date: nil,
        exit_date: '2022-12-01'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      expect(episode.days_homeless).to eq(9)
    end

    # 8. Invalid HMD (after exit)
    it 'Discard invalid HMD (after exit date)' do
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

      # PH stay with invalid Move-In date (after exit)
      # Entry: 10/1, Exit: 10/15, HMD: 10/20
      create_enrollment(
        client: @client,
        project: @ph_project,
        entry_date: '2022-10-01'.to_date,
        move_in_date: '2022-10-20'.to_date,
        exit_date: '2022-10-15'.to_date,
      )

      @report = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      @report.universe('m1a1').members.first.universe_membership
      # If HMD is discarded, it shouldn't negate shelter nights (but here it doesn't overlap anyway).
      # Actually, the spec says "Discard any HMD that is... after [project exit date]".
      # If discarded, the PH stay is treated as not-moved-in.
      # Let's make it overlap to test negation.

      # Re-setup with overlap
      @client2 = create_client_with_warehouse_link
      create_enrollment(
        client: @client2,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-11-10'.to_date,
      )
      # PH Entry 11/1, Exit 11/5, HMD 11/10 (invalid HMD)
      create_enrollment(
        client: @client2,
        project: @ph_project,
        entry_date: '2022-11-01'.to_date,
        move_in_date: '2022-11-10'.to_date,
        exit_date: '2022-11-05'.to_date,
      )

      @report2 = setup_report([@es_project.id, @ph_project.id])
      run_measure(@report2, HudSpmReport::Generators::Fy2026::MeasureOne)

      # Find episode for client2
      episode2 = @report2.universe('m1a1').members.detect { |m| m.client_id == @client2.destination_client.id }.universe_membership
      # If HMD 11/10 is discarded, then no negation happens between 11/1 and 11/5.
      # Wait, PH stays only negate AFTER move-in.
      # If HMD is invalid, it's discarded, so NO negation should happen.
      expect(episode2.days_homeless).to eq(9)
    end

    # 9. TH negating ES (Metric 1)
    it 'Metric 1: TH bed nights negate overlapping ES nights' do
      @es_project = create_project(project_type: 0) # ES-EE
      @th_project = create_project(project_type: 2) # TH
      @client = create_client_with_warehouse_link

      # ES: 2022-11-01 to 2022-11-15 (14 nights)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-11-15'.to_date,
      )

      # TH: 2022-11-05 to 2022-11-10 (5 nights: 5,6,7,8,9)
      create_enrollment(
        client: @client,
        project: @th_project,
        entry_date: '2022-11-05'.to_date,
        exit_date: '2022-11-10'.to_date,
      )

      @report = setup_report([@es_project.id, @th_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      # Original ES nights: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 (14 total)
      # TH nights: 5, 6, 7, 8, 9 (5 total)
      # Expected: 14 - 5 = 9 nights
      expect(episode.days_homeless).to eq(9)
    end

    # 10. PH move-in date before project start (Discarded)
    it 'Discard HMD before project start' do
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
      # If HMD 11/01 is discarded, no negation happens.
      # Expected: 14 days
      expect(episode.days_homeless).to eq(14)
    end

    it 'Contiguous nights: expansion stops at a gap of > 1 day when before client start date' do
      @es_project = create_project(project_type: 0) # ES-EE
      @client = create_client_with_warehouse_link

      # client_end_date will be 2023-09-30
      # client_start_date will be 2022-09-30

      # Stay 1: 2022-01-01 to 2022-01-10 (Before client_start_date)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-01'.to_date,
        exit_date: '2022-01-10'.to_date,
      )

      # GAP: 2022-01-11 to 2022-01-12 (2 days)

      # Stay 2: 2022-01-13 to 2022-01-21 (Before client_start_date)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-13'.to_date,
        exit_date: '2022-01-21'.to_date,
      )

      # GAP: 2022-01-21 (1 night) - SHOULD BE CONTIGUOUS
      # Wait, if exit is 1/21, last night is 1/20.
      # If next start is 1/22, first night is 1/22.
      # Gap is the night of 1/21. This is a 1-day gap.

      # Stay 3: 2022-01-22 to 2023-10-01 (Active during and after client_start_date)
      create_enrollment(
        client: @client,
        project: @es_project,
        entry_date: '2022-01-22'.to_date,
        exit_date: '2023-10-01'.to_date,
      )

      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

      episode = @report.universe('m1a1').members.first.universe_membership
      # client_end_date is 2023-09-30 (report end).
      # client_start_date is 2022-09-30.
      # Stay 3 starts 2022-01-22, which is before client_start_date.
      # Expansion works backward from client_start_date.
      # Stay 3 is contiguous back to 1/22.
      # Gap between Stay 3 and Stay 2 is 1 day (1/21). So Stay 2 is contiguous.
      # Gap between Stay 2 and Stay 1 is 2 days (1/11, 1/12). So Stay 1 is NOT contiguous.
      # Expansion should stop at 1/13.

      expect(episode.first_date).to eq('2022-01-13'.to_date)
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
  end
end
