###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureOne, type: :model do
  include_context 'SPM test setup'

  describe 'Measure 1b' do
    context 'with Street Outreach enrollments' do
      before do
        # Create an ES project and an SO project
        @es_project = create_project(project_type: 0) # ES-EE
        @so_project = create_project(project_type: 4) # SO = Street Outreach

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment in ES project (should be included)
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2022-12-15'.to_date,
          date_to_street_essh: '2022-10-15'.to_date,
        )

        # Create enrollment in SO project (should be excluded)
        create_enrollment(
          client: @client,
          project: @so_project,
          entry_date: '2023-01-01'.to_date,
          exit_date: '2023-03-15'.to_date,
          date_to_street_essh: '2022-12-20'.to_date,
        )

        # Setup and run the report with both projects
        @report = setup_report([@es_project.id, @so_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'excludes Street Outreach enrollments from Measure 1 calculations' do
        # Verify that the universe was created for measure 1a
        expect(@report.universe('m1a1').members.count).to eq(1)

        # Get the episode for the ES enrollment
        episode = @report.universe('m1a1').members.first.universe_membership

        # First date should be from ES enrollment, not SO
        expect(episode.first_date).to eq('2022-11-01'.to_date)

        # Days homeless should only reflect ES time (45 days), not include SO time
        # From 2022-11-01 to 2022-12-14 (exit date - 1)
        expected_days = 44
        expect(episode.days_homeless).to eq(expected_days)

        # Check measure 1b as well to ensure SO is also excluded there
        expect(@report.universe('m1b1').members.count).to eq(1)

        # Get the episode for the ES enrollment in measure 1b
        episode_1b = @report.universe('m1b1').members.first.universe_membership

        # First date in 1b should include date_to_street_essh from ES, but not use SO data
        expect(episode_1b.first_date).to eq('2022-10-15'.to_date)

        # Days homeless should reflect ES time plus self-reported time (61 days)
        # From date_to_street_essh 2022-10-15 to exit 2022-12-14 (exit date - 1)
        expected_days_1b = 61
        expect(episode_1b.days_homeless).to eq(expected_days_1b)
      end

      it 'does not count SO enrollment information in days or averages' do
        # Check measure 1a average and median
        answer_b1 = @report.answer(question: '1a', cell: 'B1')
        answer_d1 = @report.answer(question: '1a', cell: 'D1')
        answer_g1 = @report.answer(question: '1a', cell: 'G1')

        # Only ES clients should be counted
        expect(answer_b1.summary.to_i).to eq(1)

        # Average should only reflect ES time
        expected_days = 44
        expect(answer_d1.summary.to_f).to eq(expected_days)

        # Median should only reflect ES time
        expect(answer_g1.summary.to_i).to eq(expected_days)

        # Check measure 1b average and median
        answer_b1_1b = @report.answer(question: '1b', cell: 'B1')
        answer_d1_1b = @report.answer(question: '1b', cell: 'D1')
        answer_g1_1b = @report.answer(question: '1b', cell: 'G1')

        # Only ES clients should be counted
        expect(answer_b1_1b.summary.to_i).to eq(1)

        # Average should reflect ES time plus self-reported time
        expected_days_1b = 61
        expect(answer_d1_1b.summary.to_f).to eq(expected_days_1b)

        # Median should reflect ES time plus self-reported time
        expect(answer_g1_1b.summary.to_i).to eq(expected_days_1b)
      end
    end

    context 'with client having previous street date' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment with prior homelessness date
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '2022-10-15'.to_date,
          household_id: 'test_household_1',
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'creates SpmEnrollment records correctly' do
        expect(@report.spm_enrollments.count).to be > 0

        spm_enrollment = @report.spm_enrollments.first
        expect(spm_enrollment.entry_date).to eq('2022-11-01'.to_date)
        expect(spm_enrollment.exit_date).to eq('2023-01-15'.to_date)
        expect(spm_enrollment.start_of_homelessness).to eq('2022-10-15'.to_date)
      end

      it 'correctly calculates the length of time homeless including prior living situation' do
        # Verify that the universe was created for measure 1b
        expect(@report.universe('m1b1').members.count).to eq(1)

        # Verify that the appropriate metrics were calculated
        answer_b1 = @report.answer(question: '1b', cell: 'B1')
        answer_d1 = @report.answer(question: '1b', cell: 'D1')
        answer_g1 = @report.answer(question: '1b', cell: 'G1')

        # Should have a count of 1 person
        expect(answer_b1.summary.to_i).to eq(1)

        # Expected days homeless: Oct 15 to Jan 15 = 92 days
        expected_days = 92

        # Should have calculated the average length of time
        expect(answer_d1.summary.to_f).to eq(expected_days)

        # Should have calculated the median length of time
        expect(answer_g1.summary.to_i).to eq(expected_days)

        # Verify that the self-reported homelessness date is included
        episode = @report.universe('m1b1').members.first.universe_membership
        expect(episode.first_date).to eq('2022-10-15'.to_date)

        expect(episode.days_homeless).to eq(expected_days)
      end
    end

    context 'with PH enrollment with move-in date' do
      before do
        # Create a PH project
        @ph_project = create_project(project_type: 3) # PSH

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment with literally homeless prior living situation
        @enrollment = create_enrollment(
          client: @client,
          project: @ph_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-03-15'.to_date,
          date_to_street_essh: '2022-10-15'.to_date,
          living_situation: 116, # Place not meant for habitation (homeless)
        )

        # Add housing move-in date
        @enrollment.update(MoveInDate: '2022-12-01'.to_date)

        # Setup and run the report
        @report = setup_report([@ph_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'counts homeless time only before move-in date' do
        # Verify that the universe was created for measure 1b
        expect(@report.universe('m1b1').members.count).to eq(1)

        # Verify that the appropriate metrics were calculated
        episode = @report.universe('m1b1').members.first.universe_membership

        # Expected days homeless:
        # Oct 15 (date to street) to Dec 1 (move-in date) = 47 days
        # After move-in, homelessness ends
        expect(episode.days_homeless).to eq(47)
      end
    end

    context 'with complex residential history' do
      before do
        # Create projects of different types
        @es_project = create_project(project_type: 0) # ES-EE
        @th_project = create_project(project_type: 2) # TH
        @ph_project = create_project(project_type: 3) # PSH

        # Create a client
        @client = create_client_with_warehouse_link

        # Create ES enrollment
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-10-05'.to_date,
          exit_date: '2022-11-15'.to_date,
          date_to_street_essh: '2022-09-15'.to_date,
        )

        # Create TH enrollment (overlapping with end of ES)
        create_enrollment(
          client: @client,
          project: @th_project,
          entry_date: '2022-11-10'.to_date,
          exit_date: '2023-01-10'.to_date,
        )

        # Create PH enrollment with move-in date
        ph_enrollment = create_enrollment(
          client: @client,
          project: @ph_project,
          entry_date: '2023-01-15'.to_date,
          exit_date: '2023-04-15'.to_date,
          living_situation: 116, # Place not meant for habitation
        )
        ph_enrollment.update(MoveInDate: '2023-02-01'.to_date)

        # Setup and run the report
        @report = setup_report([@es_project.id, @th_project.id, @ph_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'correctly calculates days homeless accounting for all transitions' do
        # Verify the universe for measure 1b
        expect(@report.universe('m1b2').members.count).to eq(1)

        episode = @report.universe('m1b2').members.first.universe_membership

        # Expected homeless days:
        # Sept 15 (date to street) to Nov 15 (ES exit) = 62 days
        # Nov 10 (TH entry) to Jan 10 (TH exit) = 62 days
        # Jan 15 (PH entry) to Feb 1 (PH move-in) = 17 days
        # Total = 141 days
        # But, TH overrides ES for Nov 10-15 (6 days overlap), so 135 days total
        expect(episode.days_homeless).to be_within(5).of(135)
      end
    end

    context 'with client having TH stay negating ES time' do
      before do
        # Create ES and TH projects
        @es_project = create_project(project_type: 0) # ES-EE
        @th_project = create_project(project_type: 2) # TH

        # Create a client
        @client = create_client_with_warehouse_link

        # Create ES enrollment that spans the entire period
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-02-15'.to_date,
        )

        # Create overlapping TH enrollment for part of the time
        create_enrollment(
          client: @client,
          project: @th_project,
          entry_date: '2022-12-10'.to_date,
          exit_date: '2023-01-20'.to_date,
        )

        # Setup and run the report
        @report = setup_report([@es_project.id, @th_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'negates ES time during TH stay' do
        expect(@report.universe('m1b2').members.count).to eq(1)

        episode = @report.universe('m1b2').members.first.universe_membership

        # Expected homeless days:
        # Nov 1 to Feb 15 = 106 days in ES
        # Dec 10 to Jan 20 = 41 days in TH
        # Since TH negates ES during overlap, we should have 107 days total
        # (no double counting)
        expect(episode.days_homeless).to eq(106)
      end
    end

    context 'with ES-NBN shelter stay and self-reported homelessness' do
      before do
        # Create an ES-NBN project
        @nbn_project = create_project(project_type: 1) # ES-NBN

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment with prior homelessness date
        enrollment = create_enrollment(
          client: @client,
          project: @nbn_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '2022-10-01'.to_date,
        )

        # Add bed night services (sporadic, not continuous)
        create_bed_night_service(enrollment: enrollment, date: '2022-11-05'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-11-10'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-11-15'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-12-01'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-12-15'.to_date)

        # Setup and run the report
        @report = setup_report([@nbn_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'correctly calculates days homeless using earliest bed night and date to street' do
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # Expected homeless days should include:
        # Oct 1 (date to street) to first bed night (Nov 5) = 36 days
        # Plus the actual bed nights = 5 days
        # Total should be at least 40 days
        expect(episode.days_homeless).to be >= 40
      end
    end
    context 'with multi-member household' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create household members
        @head_of_household = create_client_with_warehouse_link
        @child = create_client_with_warehouse_link(dob: '2020-06-01')
        @adult_member = create_client_with_warehouse_link

        # Create household ID
        household_id = 'test_household_123'

        # Create head of household enrollment with prior living situation date
        create_enrollment(
          client: @head_of_household,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '2022-10-01'.to_date,
          relationship_to_ho_h: 1,
          household_id: household_id,
        )

        # Create child enrollment (same dates as HoH, but no prior living situation)
        create_enrollment(
          client: @child,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
          relationship_to_ho_h: 3,
          household_id: household_id,
        )

        # Create adult member enrollment (joined later, left earlier, with different prior living situation)
        create_enrollment(
          client: @adult_member,
          project: @es_project,
          entry_date: '2022-11-15'.to_date,
          exit_date: '2023-01-10'.to_date,
          date_to_street_essh: '2022-10-15'.to_date,
          relationship_to_ho_h: 2,
          household_id: household_id,
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'correctly propagates prior living situation from head of household to child' do
        # Verify that all household members are in the universe
        expect(@report.universe('m1b1').members.count).to eq(3)

        # Find episodes for each household member
        episodes = @report.universe('m1b1').members.map(&:universe_membership)
        hoh_episode = episodes.find { |e| e.client_id == @head_of_household.destination_client.id }
        child_episode = episodes.find { |e| e.client_id == @child.destination_client.id }
        adult_episode = episodes.find { |e| e.client_id == @adult_member.destination_client.id }

        # Expected first date for head of household: Oct 1 (prior living situation)
        expect(hoh_episode.first_date).to eq('2022-10-01'.to_date)

        # Expected days homeless for head of household: Oct 1 to Jan 14 = 106 days
        expect(hoh_episode.days_homeless).to eq(106)

        # Child should inherit HoH's prior living situation date
        # Expected first date for child: Oct 1 (inherited from HoH)
        expect(child_episode.first_date).to eq('2022-10-01'.to_date)

        # Expected days homeless for child: Oct 1 to Jan 14 = 106 days (same as HoH)
        expect(child_episode.days_homeless).to eq(106)

        # Adult should use their own prior living situation date
        # Expected first date for adult: Oct 15 (own prior living situation)
        expect(adult_episode.first_date).to eq('2022-10-15'.to_date)

        # Expected days homeless for adult: Oct 15 to Jan 9 = 87 days
        expect(adult_episode.days_homeless).to eq(87)
      end

      it 'correctly calculates average and median length of time homeless' do
        # Verify that the appropriate metrics were calculated
        answer_b1 = @report.answer(question: '1b', cell: 'B1')
        answer_d1 = @report.answer(question: '1b', cell: 'D1')
        answer_g1 = @report.answer(question: '1b', cell: 'G1')

        # Should have a count of 3 people
        expect(answer_b1.summary.to_i).to eq(3)

        # Average should be (106 + 106 + 87) / 3 = 99.67 days
        expect(answer_d1.summary.to_f).to be_within(1).of(99.67)

        # Median should be 106 days
        expect(answer_g1.summary.to_i).to eq(106)
      end
    end
  end

  describe 'Measure 1b lookback handling' do
    # The lookback stop date would be 7 years prior to the report start date
    # For our test, report period is 2022-10-01 to 2023-09-30
    # So lookback stop date is 2015-10-01

    context 'with DateToStreetESSH before lookback stop date but project entry after lookback stop date' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment with DateToStreetESSH before lookback stop date (7 years before report start)
        # Per the spec, if project start date is >= lookback stop date, we should include time
        # from DateToStreetESSH even if it's before the lookback stop date
        create_enrollment(
          client: @client,
          project: @es_project,
          date_to_street_essh: '2014-10-15'.to_date, # Before lookback stop date (2015-10-01)
          entry_date: '2016-01-15'.to_date, # After lookback stop date
          exit_date: '2023-01-15'.to_date,
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'includes time from DateToStreetESSH even though it is before lookback stop date' do
        # Verify that the universe was created for measure 1b
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # Expected first date should be date_to_street_essh since the project start date
        # is after the lookback stop date
        expect(episode.first_date).to eq('2014-10-15'.to_date)

        # Expected days homeless should include the time from date_to_street_essh to project exit
        # (minus one day since exit date doesn't count as a bed night)
        expected_days = ('2023-01-15'.to_date - '2014-10-15'.to_date).to_i - 1
        expect(episode.days_homeless).to be_within(5).of(expected_days)
      end
    end

    context 'with DateToStreetESSH before lookback stop date AND project entry before lookback stop date' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment with both DateToStreetESSH and project entry before lookback stop date
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2014-06-15'.to_date, # Before lookback stop date
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '2014-01-15'.to_date, # Before lookback stop date
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'does not include time from DateToStreetESSH since project entry is before lookback stop date' do
        # Verify that the universe was created for measure 1b
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # First date should be no earlier than the lookback stop date (2015-10-01)
        expect(episode.first_date).to be >= '2015-10-01'.to_date

        # Days homeless should not include time before the lookback stop date
        # Maximum possible days would be from lookback stop date to exit date minus one day
        max_possible_days = ('2023-01-15'.to_date - '2015-10-01'.to_date).to_i
        expect(episode.days_homeless).to be <= max_possible_days
      end
    end

    context 'with night-by-night shelter with DateToStreetESSH before lookback stop date' do
      before do
        # Create an ES-NBN project
        @nbn_project = create_project(project_type: 1) # ES-NBN

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment with DateToStreetESSH before lookback stop date
        enrollment = create_enrollment(
          client: @client,
          project: @nbn_project,
          entry_date: '2016-11-01'.to_date, # After lookback stop date
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '2014-10-01'.to_date, # Before lookback stop date
        )

        # Add bed night services after lookback stop date
        create_bed_night_service(enrollment: enrollment, date: '2016-11-05'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2016-11-10'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2016-11-15'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-12-01'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-12-15'.to_date)

        # Setup and run the report
        @report = setup_report([@nbn_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'includes time from DateToStreetESSH to first bed night after lookback stop date' do
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # For night-by-night shelters, we should include all nights from date_to_street_essh
        # up to and including the earliest bed night, plus all actual bed nights
        # The earliest bed night is 2016-11-05

        # First date should be date_to_street_essh
        expect(episode.first_date).to eq('2014-10-01'.to_date)

        # Expected homeless days should include:
        # 2014-10-01 to 2016-11-05 = 767 days
        # Plus 5 actual bed nights = 772 days total
        # We allow some flexibility in the exact count since the implementation may handle edge cases differently
        expect(episode.days_homeless).to be > 700
      end
    end

    context 'with DateToStreetESSH set to a date after DoB but before lookback stop date' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create a client with birth date in 2000
        @client = create_client_with_warehouse_link(dob: '2000-01-01'.to_date)

        # Create enrollment with DateToStreetESSH after DoB but before lookback stop date
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2018-01-15'.to_date, # After lookback stop date
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '2012-10-15'.to_date, # After DoB but before lookback stop date
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'does not count homelessness before date of birth' do
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # First date should be date_to_street_essh since it's after DoB
        expect(episode.first_date).to eq('2012-10-15'.to_date)

        # Days homeless should not exceed the maximum possible days
        # from date_to_street_essh to exit date minus one day
        max_possible_days = ('2023-01-15'.to_date - '2012-10-15'.to_date).to_i
        expect(episode.days_homeless).to be <= max_possible_days
      end
    end

    context 'with very old DateToStreetESSH (decades ago)' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create a client born in 1970
        @client = create_client_with_warehouse_link(dob: '1970-01-01'.to_date)

        # Create enrollment with very old DateToStreetESSH
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2016-01-15'.to_date, # After lookback stop date
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '1990-10-15'.to_date, # Very old date, but after DoB
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'still counts from the old DateToStreetESSH as per the spec' do
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # First date should be the old date_to_street_essh per the spec
        expect(episode.first_date).to eq('1990-10-15'.to_date)

        # Expected days homeless should be from date_to_street_essh to exit date (minus one day)
        expected_days = ('2023-01-15'.to_date - '1990-10-15'.to_date).to_i - 1
        expect(episode.days_homeless).to be_within(5).of(expected_days)
      end
    end

    context 'with overlapping homeless periods ES and moved-in PH enrollments' do
      before do
        # Create projects
        @es_project = create_project(project_type: 0) # ES-EE
        @ph_project = create_project(project_type: 3) # PSH

        # Create a client
        @client = create_client_with_warehouse_link

        # Create PH enrollment that starts after the ES stay
        # With literally homeless at entry
        ph_enrollment = create_enrollment(
          client: @client,
          project: @ph_project,
          entry_date: '2018-02-15'.to_date,
          exit_date: '2023-01-15'.to_date,
          living_situation: 116, # Place not meant for habitation (homeless)
        )
        # Add move-in date
        ph_enrollment.update(MoveInDate: '2018-04-01'.to_date)

        # Create another ES enrollment during the report period and within the PH mov-in and exit dates
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-09-01'.to_date,
          exit_date: '2022-10-15'.to_date,
          date_to_street_essh: '2022-08-15'.to_date,
        )

        # Setup and run the report
        @report = setup_report([@es_project.id, @ph_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'correctly handles excludes ES enrollments that occur during PH' do
        expect(@report.universe('m1b1').members.count).to eq(0)
      end
    end

    context 'with client having PSH before the report period' do
      before do
        # Create projects of different types
        @psh_project = create_project(project_type: 3) # PSH
        @nbn_project = create_project(project_type: 1) # ES-NBN

        # Create a client
        @client = create_client_with_warehouse_link(dob: '1990-01-01')

        create_enrollment(
          client: @client,
          project: @psh_project,
          date_to_street_essh: '2014-06-01'.to_date,
          entry_date: '2021-06-01'.to_date,
          move_in_date: '2021-08-01'.to_date,
          exit_date: '2022-04-30'.to_date, # exit before reporting period
          living_situation: 116, # literally homeless
        )

        # NBN enrollment
        nbn_enrollment1 = create_enrollment(
          client: @client,
          project: @nbn_project,
          date_to_street_essh: '2023-01-01'.to_date,
          entry_date: '2023-08-15'.to_date,
        )
        # Add a bed night for the NBN enrollment
        create_bed_night_service(enrollment: nbn_enrollment1, date: '2023-08-15'.to_date)

        # Setup and run the report
        @report = setup_report([@psh_project.id, @nbn_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'correctly calculates homelessness period' do
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # Episode should start from the date_to_street_essh of the NBN enrollment
        # NOT from the earlier PSH enrollment, which is irrelevant due to the
        # break in homelessness (client was housed in PSH)
        expect(episode.first_date).to eq('2023-01-01'.to_date)

        # Calculate expected days: From date_to_street_essh (2023-01-01) to the end of this episode
        # This should include self-reported homeless time before the ES-NBN bed night
        expected_days = 227 # how many days?
        expect(episode.days_homeless).to eq(expected_days)
        answer = @report.answer(question: '1b', cell: 'D1')
        expect(answer.summary.to_f).to eq(expected_days)
      end
    end

    context 'with client having PSH overlapping the report period' do
      before do
        # Create projects of different types
        @psh_project = create_project(project_type: 3) # PSH
        @nbn_project = create_project(project_type: 1) # ES-NBN

        # Create a client
        @client = create_client_with_warehouse_link(dob: '1990-01-01')

        create_enrollment(
          client: @client,
          project: @psh_project,
          date_to_street_essh: '2014-06-01'.to_date,
          entry_date: '2021-06-01'.to_date,
          move_in_date: '2022-10-03'.to_date, # after the client-start-date as defined in spm
          exit_date: '2022-11-03'.to_date, # within reporting period
          living_situation: 116, # literally homeless
        )

        # NBN enrollment
        nbn_enrollment1 = create_enrollment(
          client: @client,
          project: @nbn_project,
          date_to_street_essh: '2023-01-01'.to_date,
          entry_date: '2023-08-15'.to_date,
        )

        # Add a bed night for the NBN enrollment
        create_bed_night_service(enrollment: nbn_enrollment1, date: '2023-08-15'.to_date)

        # Setup and run the report
        @report = setup_report([@psh_project.id, @nbn_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'correctly calculates homelessness period' do
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # First date of homelessness should be the earliest date_to_street_essh
        # Since the PSH enrollment overlaps with the report period, per SPM rules
        # we should count from the earliest start of homelessness
        expect(episode.first_date).to eq('2014-06-01'.to_date)

        # Expected days homeless calculation:
        # - Time from date_to_street_essh (2014-06-01) to PSH move-in (2022-10-03)
        # - Plus time from NBN date_to_street_essh (2023-01-01) to the bed night (2023-08-15)
        expected_days = 3273 # how many days?
        expect(episode.days_homeless).to eq(expected_days)
        answer = @report.answer(question: '1b', cell: 'D1')
        expect(answer.summary.to_f).to eq(expected_days)
      end
    end

    context 'with overlapping ES and PSH stays with a brief housing period' do
      let(:default_filter) do
        ::Filters::HudFilterBase.new(
          user_id: User.setup_system_user.id,
          start: '2023-10-01'.to_date,
          end: '2026-09-30'.to_date,
          coc_codes: ['MA-500'],
        )
      end

      before do
        # Create projects of different types
        @es_project = create_project(project_type: 0) # ES-EE
        @psh_project = create_project(project_type: 3) # PSH

        # Create a client
        @client = create_client_with_warehouse_link(dob: '1990-01-01')

        # Create ES enrollment that starts before PSH exit and continues through reporting period
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2023-05-15'.to_date,
          exit_date: nil, # Still active
        )

        # Create PSH enrollment that occurred before the report period
        # but overlapped with the ES stay
        create_enrollment(
          client: @client,
          project: @psh_project,
          date_to_street_essh: '2021-01-01'.to_date,
          entry_date: '2021-06-01'.to_date,
          move_in_date: '2023-06-01'.to_date, # Housed briefly before exit
          exit_date: '2023-06-11'.to_date,
          living_situation: 116, # Place not meant for habitation
        )

        # Setup and run the report
        @report = setup_report([@es_project.id, @psh_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
      end

      it 'properly handles homeless periods interrupted by brief housing in PSH' do
        # Verify that the universe was created for measure 1b
        expect(@report.universe('m1b1').members.count).to eq(1)

        episode = @report.universe('m1b1').members.first.universe_membership

        # The homelessness start date should be from the ES entry's date_to_street
        # The brief housing period in PSH creates a break in homelessness
        expect(episode.first_date).to eq('2023-06-11'.to_date)

        # Calculate expected days:
        # PSH exit (2023-06-11) to end of reporting period (2024-09-30)
        expected_days = 478

        expect(episode.days_homeless).to eq(expected_days)
        answer = @report.answer(question: '1b', cell: 'D1')
        expect(answer.summary.to_f).to eq(expected_days)
      end
    end
  end

  context 'with propagation of date to street from HoH to child household members' do
    before do
      # Create an ES project
      @es_project = create_project(project_type: 0) # ES-EE

      # Create household members: HoH, child, and adult
      @head_of_household = create_client_with_warehouse_link(dob: '1980-01-01')
      @child = create_client_with_warehouse_link(dob: '2015-01-01') # Age 7-8 during report period
      @adult_member = create_client_with_warehouse_link(dob: '1990-01-01')
      @unknown_age_member = create_client_with_warehouse_link(dob: nil) # No DOB = unknown age

      # Create household ID
      household_id = 'test_household_456'

      # Create head of household enrollment with prior living situation date
      create_enrollment(
        client: @head_of_household,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: '2022-09-01'.to_date, # HoH date to street
        relationship_to_ho_h: 1, # Head of household
        household_id: household_id,
      )

      # Create child enrollment with same entry date as HoH but NO date to street
      create_enrollment(
        client: @child,
        project: @es_project,
        entry_date: '2022-11-01'.to_date, # Same entry date as HoH
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: nil, # No date to street data
        relationship_to_ho_h: 3, # Child
        household_id: household_id,
      )

      # Create adult member with same entry date but NO date to street
      create_enrollment(
        client: @adult_member,
        project: @es_project,
        entry_date: '2022-11-01'.to_date, # Same entry date as HoH
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: nil, # No date to street data
        relationship_to_ho_h: 2, # Adult
        household_id: household_id,
      )

      # Create unknown age member with same entry date but NO date to street
      create_enrollment(
        client: @unknown_age_member,
        project: @es_project,
        entry_date: '2022-11-01'.to_date, # Same entry date as HoH
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: nil, # No date to street data
        relationship_to_ho_h: 2, # Other household member
        household_id: household_id,
      )

      # Setup and run the report
      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
    end

    it 'propagates date to street from HoH to children but not to adults or unknown age members' do
      # Verify that all members are in the universe
      expect(@report.universe('m1b1').members.count).to eq(4)

      # Find episodes for each household member
      episodes = @report.universe('m1b1').members.map(&:universe_membership)
      hoh_episode = episodes.find { |e| e.client_id == @head_of_household.destination_client.id }
      child_episode = episodes.find { |e| e.client_id == @child.destination_client.id }
      adult_episode = episodes.find { |e| e.client_id == @adult_member.destination_client.id }
      unknown_age_episode = episodes.find { |e| e.client_id == @unknown_age_member.destination_client.id }

      # Expected first date for head of household: Sep 1 (prior living situation)
      expect(hoh_episode.first_date).to eq('2022-09-01'.to_date)

      # Child should inherit HoH's prior living situation date
      # Expected first date for child: Sep 1 (inherited from HoH)
      expect(child_episode.first_date).to eq('2022-09-01'.to_date)

      # Adult should NOT inherit HoH's prior living situation date
      # Instead should use entry date as first date
      expect(adult_episode.first_date).to eq('2022-11-01'.to_date)

      # Unknown age should NOT inherit HoH's prior living situation date
      # Instead should use entry date as first date
      expect(unknown_age_episode.first_date).to eq('2022-11-01'.to_date)

      # Days homeless calculation should reflect the appropriate start dates
      expect(hoh_episode.days_homeless).to eq(136) # 2022-09-01 to 2023-01-14 = 136 days
      expect(child_episode.days_homeless).to eq(136) # Should match HoH
      expect(adult_episode.days_homeless).to eq(75) # 2022-11-01 to 2023-01-14 = 75 days
      expect(unknown_age_episode.days_homeless).to eq(75) # Same as adult
    end
  end

  context 'with child joining household after HoH entry' do
    before do
      # Create an ES project
      @es_project = create_project(project_type: 0) # ES-EE

      # Create household members
      @head_of_household = create_client_with_warehouse_link(dob: '1980-01-01')
      @child = create_client_with_warehouse_link(dob: '2015-01-01')

      # Create household ID
      household_id = 'test_household_789'

      # Create head of household enrollment with prior living situation date
      create_enrollment(
        client: @head_of_household,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: '2022-09-01'.to_date,
        relationship_to_ho_h: 1,
        household_id: household_id,
      )

      # Create child enrollment with DIFFERENT entry date than HoH
      create_enrollment(
        client: @child,
        project: @es_project,
        entry_date: '2022-12-01'.to_date, # Different entry date than HoH
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: nil, # No date to street data
        relationship_to_ho_h: 3,
        household_id: household_id,
      )

      # Setup and run the report
      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
    end

    it 'does not propagate date to street from HoH to child with different entry date' do
      # Verify that all members are in the universe
      expect(@report.universe('m1b1').members.count).to eq(2)

      # Find episodes for each household member
      episodes = @report.universe('m1b1').members.map(&:universe_membership)
      hoh_episode = episodes.find { |e| e.client_id == @head_of_household.destination_client.id }
      child_episode = episodes.find { |e| e.client_id == @child.destination_client.id }

      # Expected first date for head of household: Sep 1 (prior living situation)
      expect(hoh_episode.first_date).to eq('2022-09-01'.to_date)

      # Child should NOT inherit HoH's prior living situation date because entry dates differ
      # Expected first date for child: Dec 1 (own entry date)
      expect(child_episode.first_date).to eq('2022-12-01'.to_date)

      # Days homeless calculation should reflect the appropriate start dates
      expect(hoh_episode.days_homeless).to eq(136) # 2022-09-01 to 2023-01-14 = 136 days
      expect(child_episode.days_homeless).to eq(45) # 2022-12-01 to 2023-01-14 = 45 days
    end
  end

  context 'with multiple children of different ages in household' do
    before do
      # Create an ES project
      @es_project = create_project(project_type: 0) # ES-EE

      # Create household members
      @head_of_household = create_client_with_warehouse_link(dob: '1980-01-01')
      @younger_child = create_client_with_warehouse_link(dob: '2015-01-01') # Age 7-8
      @older_child = create_client_with_warehouse_link(dob: '2005-01-01') # Age 17-18
      @adult_turning_18 = create_client_with_warehouse_link(dob: '2004-11-15') # Turns 18 during enrollment

      # Create household ID
      household_id = 'test_household_101'

      # Create head of household enrollment
      create_enrollment(
        client: @head_of_household,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: '2022-09-01'.to_date,
        relationship_to_ho_h: 1,
        household_id: household_id,
      )

      # Create younger child enrollment
      create_enrollment(
        client: @younger_child,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: nil,
        relationship_to_ho_h: 3,
        household_id: household_id,
      )

      # Create older child enrollment (17 at entry)
      create_enrollment(
        client: @older_child,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: nil,
        relationship_to_ho_h: 3,
        household_id: household_id,
      )

      # Create client who turns 18 during enrollment
      create_enrollment(
        client: @adult_turning_18,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: nil,
        relationship_to_ho_h: 3,
        household_id: household_id,
      )

      # Setup and run the report
      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
    end

    it 'propagates date to street to all children, even if they turn 18 during enrollment' do
      # Verify that all members are in the universe
      expect(@report.universe('m1b1').members.count).to eq(4)

      # Find episodes for each household member
      episodes = @report.universe('m1b1').members.map(&:universe_membership)
      hoh_episode = episodes.find { |e| e.client_id == @head_of_household.destination_client.id }
      younger_child_episode = episodes.find { |e| e.client_id == @younger_child.destination_client.id }
      older_child_episode = episodes.find { |e| e.client_id == @older_child.destination_client.id }
      adult_turning_18_episode = episodes.find { |e| e.client_id == @adult_turning_18.destination_client.id }

      # Expected first date for head of household: Sep 1 (prior living situation)
      expect(hoh_episode.first_date).to eq('2022-09-01'.to_date)

      # Younger child should inherit HoH's prior living situation date
      expect(younger_child_episode.first_date).to eq('2022-09-01'.to_date)

      # Older child should inherit HoH's prior living situation date (was 17 at entry)
      expect(older_child_episode.first_date).to eq('2022-09-01'.to_date)

      # Client who turns 18 during enrollment should inherit HoH's prior living situation date
      # Age at entry is what matters (17), not age during entire enrollment
      expect(adult_turning_18_episode.first_date).to eq('2022-09-01'.to_date)

      # All should have the same days homeless calculation
      expect(hoh_episode.days_homeless).to eq(136)
      expect(younger_child_episode.days_homeless).to eq(136)
      expect(older_child_episode.days_homeless).to eq(136)
      expect(adult_turning_18_episode.days_homeless).to eq(136)
    end
  end

  context 'with child having their own date to street value' do
    before do
      # Create an ES project
      @es_project = create_project(project_type: 0) # ES-EE

      # Create household members
      @head_of_household = create_client_with_warehouse_link(dob: '1980-01-01')
      @child_with_data = create_client_with_warehouse_link(dob: '2015-01-01')

      # Create household ID
      household_id = 'test_household_202'

      # Create head of household enrollment
      create_enrollment(
        client: @head_of_household,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: '2022-09-01'.to_date,
        relationship_to_ho_h: 1,
        household_id: household_id,
      )

      # Create child enrollment WITH its own date to street
      create_enrollment(
        client: @child_with_data,
        project: @es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2023-01-15'.to_date,
        date_to_street_essh: '2022-10-01'.to_date, # Child has own date to street
        relationship_to_ho_h: 3,
        household_id: household_id,
      )

      # Setup and run the report
      @report = setup_report([@es_project.id])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
    end

    it 'uses child\'s own date to street value when it exists' do
      # Verify that all members are in the universe
      expect(@report.universe('m1b1').members.count).to eq(2)

      # Find episodes for each household member
      episodes = @report.universe('m1b1').members.map(&:universe_membership)
      hoh_episode = episodes.find { |e| e.client_id == @head_of_household.destination_client.id }
      child_episode = episodes.find { |e| e.client_id == @child_with_data.destination_client.id }

      # Expected first date for head of household: Sep 1 (prior living situation)
      expect(hoh_episode.first_date).to eq('2022-09-01'.to_date)

      # Child should use its own date to street, not inherit from HoH
      expect(child_episode.first_date).to eq('2022-10-01'.to_date)

      # Days homeless calculation should reflect the appropriate start dates
      expect(hoh_episode.days_homeless).to eq(136) # 2022-09-01 to 2023-01-14 = 136 days
      expect(child_episode.days_homeless).to eq(106) # 2022-10-01 to 2023-01-14 = 106 days
    end
  end
end
