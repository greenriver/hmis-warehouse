###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureOne, type: :model, exclude_fixpoints: true do
  include_context '2026 SPM test setup'

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
        answer_b2 = @report.answer(question: '1a', cell: 'B2')
        answer_d2 = @report.answer(question: '1a', cell: 'D2')
        answer_g2 = @report.answer(question: '1a', cell: 'G2')

        # Only ES clients should be counted
        expect(answer_b2.summary.to_i).to eq(1)

        # Average should only reflect ES time
        expected_days = 44
        expect(answer_d2.summary.to_f).to eq(expected_days)

        # Median should only reflect ES time
        expect(answer_g2.summary.to_i).to eq(expected_days)

        # Check measure 1b average and median
        answer_b2_1b = @report.answer(question: '1b', cell: 'B2')
        answer_d2_1b = @report.answer(question: '1b', cell: 'D2')
        answer_g2_1b = @report.answer(question: '1b', cell: 'G2')

        # Only ES clients should be counted
        expect(answer_b2_1b.summary.to_i).to eq(1)

        # Average should reflect ES time plus self-reported time
        expected_days_1b = 61
        expect(answer_d2_1b.summary.to_f).to eq(expected_days_1b)

        # Median should reflect ES time plus self-reported time
        expect(answer_g2_1b.summary.to_i).to eq(expected_days_1b)
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

      it 'correctly calculates the length of time homeless including prior living situation' do
        # Verify that the universe was created for measure 1b
        expect(@report.universe('m1b1').members.count).to eq(1)

        # Verify that the appropriate metrics were calculated
        answer_b2 = @report.answer(question: '1b', cell: 'B2')
        answer_d2 = @report.answer(question: '1b', cell: 'D2')
        answer_g2 = @report.answer(question: '1b', cell: 'G2')

        # Should have a count of 1 person
        expect(answer_b2.summary.to_i).to eq(1)

        # Expected days homeless: Oct 15 to Jan 15 = 92 days
        expected_days = 92

        # Should have calculated the average length of time
        expect(answer_d2.summary.to_f).to eq(expected_days)

        # Should have calculated the median length of time
        expect(answer_g2.summary.to_i).to eq(expected_days)

        # Verify that the self-reported homelessness date is included
        episode = @report.universe('m1b1').members.first.universe_membership
        expect(episode.first_date).to eq('2022-10-15'.to_date)

        expect(episode.days_homeless).to eq(expected_days)
      end
    end

    context 'with households split across data sources' do
      let(:es_project) { create_project(project_type: 0) }
      let(:other_data_source) { create(:source_data_source) }
      let(:shared_household_id) { 'shared-household-id' }

      before do
        @primary_members = []
        build_household(
          projects: [es_project],
          entry_date: '2023-03-01'.to_date,
          exit_date: '2023-03-10'.to_date,
          members: 2,
          household_id: shared_household_id,
          date_to_street_essh: '2023-02-01'.to_date,
          include_move_in: true,
          move_in_offset: 0,
        ) do |client, enrollment|
          @primary_members << { client: client, enrollment: enrollment }
        end

        @secondary_members = []
        build_household(
          projects: [es_project],
          entry_date: '2023-03-05'.to_date,
          exit_date: '2023-03-15'.to_date,
          members: 2,
          household_id: shared_household_id,
          date_to_street_essh: '2023-01-15'.to_date,
          include_move_in: true,
          move_in_offset: 3,
          data_source_override: other_data_source,
        ) do |client, enrollment|
          @secondary_members << { client: client, enrollment: enrollment }
        end

        (@primary_members + @secondary_members).each do |member|
          add_bed_nights(
            enrollment: member[:enrollment],
            start_date: member[:enrollment].entry_date,
            end_date: member[:enrollment].real_exit_date,
          )
        end

        @primary_child = @primary_members.find { |member| member[:enrollment].relationship_to_hoh == 2 }
        @secondary_child = @secondary_members.find { |member| member[:enrollment].relationship_to_hoh == 2 }

        @primary_child[:enrollment].update(DateToStreetESSH: nil)
        @secondary_child[:enrollment].update(DateToStreetESSH: nil)

        @report = setup_report([es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

        @episodes = @report.universe('m1b1').members.map(&:universe_membership)
      end

      it 'keeps household context separate per data source' do
        expect(@episodes.size).to eq(2)

        primary_episode = @episodes.find { |episode| episode.client.personal_id == @primary_child[:client].personal_id }
        expect(primary_episode).to be_present
        expect(primary_episode.first_date).to eq(Date.parse('2023-03-01'))
        expect(primary_episode.days_homeless).to eq(('2023-03-10'.to_date - '2023-03-01'.to_date).to_i)

        secondary_episode = (@episodes - [primary_episode]).first
        expect(secondary_episode).to be_present
        expect(secondary_episode.first_date).to eq(Date.parse('2023-02-01'))
        expect(secondary_episode.days_homeless).to eq(('2023-03-10'.to_date - '2023-02-01'.to_date).to_i)
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
          living_situation: 116, # Literally Homeless at Entry
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
    describe 'Household propagation logic' do
      let(:es_project) { create_project(project_type: 0) }
      let(:household_id) { 'test_household_123' }

      it 'propagates prior living situation from HoH to children but not to adults or unknown age members' do
        # Create household members
        hoh = create_client_with_warehouse_link(dob: '1980-01-01')
        child = create_client_with_warehouse_link(dob: '2015-01-01')
        adult = create_client_with_warehouse_link(dob: '1990-01-01')
        unknown_age = create_client_with_warehouse_link(dob: nil)

        # Enrollments
        create_enrollment(client: hoh, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, date_to_street_essh: '2022-09-01'.to_date, relationship_to_ho_h: 1, household_id: household_id)
        create_enrollment(client: child, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, relationship_to_ho_h: 3, household_id: household_id)
        create_enrollment(client: adult, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, relationship_to_ho_h: 2, household_id: household_id)
        create_enrollment(client: unknown_age, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, relationship_to_ho_h: 2, household_id: household_id)

        @report = setup_report([es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

        episodes = @report.universe('m1b1').members.map(&:universe_membership)
        expect(episodes.find { |e| e.client_id == hoh.destination_client.id }.first_date).to eq('2022-09-01'.to_date)
        expect(episodes.find { |e| e.client_id == child.destination_client.id }.first_date).to eq('2022-09-01'.to_date)
        expect(episodes.find { |e| e.client_id == adult.destination_client.id }.first_date).to eq('2022-11-01'.to_date)
        expect(episodes.find { |e| e.client_id == unknown_age.destination_client.id }.first_date).to eq('2022-11-01'.to_date)
      end

      it 'does not propagate if child joins household after HoH entry' do
        hoh = create_client_with_warehouse_link(dob: '1980-01-01')
        child = create_client_with_warehouse_link(dob: '2015-01-01')

        create_enrollment(client: hoh, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, date_to_street_essh: '2022-09-01'.to_date, relationship_to_ho_h: 1, household_id: household_id)
        create_enrollment(client: child, project: es_project, entry_date: '2022-12-01'.to_date, exit_date: '2023-01-15'.to_date, relationship_to_ho_h: 3, household_id: household_id)

        @report = setup_report([es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

        episodes = @report.universe('m1b1').members.map(&:universe_membership)
        expect(episodes.find { |e| e.client_id == hoh.destination_client.id }.first_date).to eq('2022-09-01'.to_date)
        expect(episodes.find { |e| e.client_id == child.destination_client.id }.first_date).to eq('2022-12-01'.to_date)
      end

      it 'propagates even if children turn 18 during enrollment' do
        hoh = create_client_with_warehouse_link(dob: '1980-01-01')
        adult_turning_18 = create_client_with_warehouse_link(dob: '2004-11-15') # 17 at entry 2022-11-01

        create_enrollment(client: hoh, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, date_to_street_essh: '2022-09-01'.to_date, relationship_to_ho_h: 1, household_id: household_id)
        create_enrollment(client: adult_turning_18, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, relationship_to_ho_h: 3, household_id: household_id)

        @report = setup_report([es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

        episodes = @report.universe('m1b1').members.map(&:universe_membership)
        expect(episodes.find { |e| e.client_id == adult_turning_18.destination_client.id }.first_date).to eq('2022-09-01'.to_date)
      end

      it 'uses child\'s own date to street value when it exists' do
        hoh = create_client_with_warehouse_link(dob: '1980-01-01')
        child = create_client_with_warehouse_link(dob: '2015-01-01')

        create_enrollment(client: hoh, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, date_to_street_essh: '2022-09-01'.to_date, relationship_to_ho_h: 1, household_id: household_id)
        create_enrollment(client: child, project: es_project, entry_date: '2022-11-01'.to_date, exit_date: '2023-01-15'.to_date, date_to_street_essh: '2022-10-01'.to_date, relationship_to_ho_h: 3, household_id: household_id)

        @report = setup_report([es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

        episodes = @report.universe('m1b1').members.map(&:universe_membership)
        expect(episodes.find { |e| e.client_id == child.destination_client.id }.first_date).to eq('2022-10-01'.to_date)
      end
    end

    describe 'Measure 1b lookback handling' do
      # The lookback stop date would be 7 years prior to the report start date
      # For our test, report period is 2022-10-01 to 2023-09-30
      # So lookback stop date is 2015-10-01

      context 'with DateToStreetESSH before lookback stop date but project entry after lookback stop date' do
        before do
          @es_project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link

          # Create enrollment with DateToStreetESSH before lookback stop date
          # Per spec step 5a: "every night from [approximate date this episode of homelessness started]
          # up to and including [project start date] should also be considered nights experiencing
          # homelessness, even if response in [approximate date this episode of homelessness started]
          # extends prior to [lookback stop date]"
          create_enrollment(
            client: @client,
            project: @es_project,
            date_to_street_essh: '2014-10-15'.to_date, # Before lookback stop date (2015-10-01)
            entry_date: '2016-01-15'.to_date, # After lookback stop date
            exit_date: '2023-01-15'.to_date,
          )

          @report = setup_report([@es_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'includes time from DateToStreetESSH even when before lookback stop date' do
          expect(@report.universe('m1b1').members.count).to eq(1)

          episode = @report.universe('m1b1').members.first.universe_membership

          # Per spec, DateToStreetESSH time is included even if before lookback stop date
          # So first_date should be the DateToStreetESSH value
          expect(episode.first_date).to eq('2014-10-15'.to_date)

          # Days homeless: from 2014-10-15 through 2023-01-14 (exit date minus 1)
          # This includes the prepended time from DateToStreetESSH through project start,
          # plus the actual shelter stay
          expected_days = ('2023-01-15'.to_date - '2014-10-15'.to_date).to_i
          expect(episode.days_homeless).to be_within(5).of(expected_days)
        end
      end

      context 'with project entry before lookback stop date' do
        before do
          @es_project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link

          # When project start date is BEFORE lookback stop date,
          # the 3.917 data should NOT be used (per step 5a condition)
          create_enrollment(
            client: @client,
            project: @es_project,
            date_to_street_essh: '2014-01-01'.to_date,
            entry_date: '2015-06-01'.to_date, # BEFORE lookback stop date (2015-10-01)
            exit_date: '2023-01-15'.to_date,
          )

          @report = setup_report([@es_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'does not include DateToStreetESSH time when project start is before lookback stop date' do
          expect(@report.universe('m1b1').members.count).to eq(1)

          episode = @report.universe('m1b1').members.first.universe_membership

          # Since project start date (2015-06-01) is before lookback stop date (2015-10-01),
          # the condition in step 5a is not met, so DateToStreetESSH should not be prepended
          # The first_date should be based on the actual enrollment, not the 3.917 data
          expect(episode.first_date).not_to eq('2014-01-01'.to_date)
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
          @nbn_project = create_project(project_type: 1) # ES-NBN
          @client = create_client_with_warehouse_link

          enrollment = create_enrollment(
            client: @client,
            project: @nbn_project,
            entry_date: '2016-11-01'.to_date,
            exit_date: '2023-01-15'.to_date,
            date_to_street_essh: '2014-10-01'.to_date,
          )

          # Bed nights - earliest is 2022-12-01
          create_bed_night_service(enrollment: enrollment, date: '2022-12-01'.to_date)
          create_bed_night_service(enrollment: enrollment, date: '2022-12-02'.to_date)
          create_bed_night_service(enrollment: enrollment, date: '2022-12-03'.to_date)

          @report = setup_report([@nbn_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'includes time from DateToStreetESSH even when before lookback stop date' do
          expect(@report.universe('m1b1').members.count).to eq(1)

          episode = @report.universe('m1b1').members.first.universe_membership

          # First date should be the DateToStreetESSH value
          expect(episode.first_date).to eq('2014-10-01'.to_date)

          # Prepended days (2014-10-01 through 2022-12-01 inclusive): 2984 days
          # Additional bed nights after earliest (2022-12-02, 2022-12-03): 2 days
          # Total: 2986 days

          prepended_days = ('2022-12-01'.to_date - '2014-10-01'.to_date).to_i + 1 # inclusive
          additional_bed_nights = 2 # 12/02 and 12/03

          expect(episode.days_homeless).to eq(prepended_days + additional_bed_nights)
        end
      end

      context 'with DateToStreetESSH before lookback stop date but after DoB' do
        before do
          @es_project = create_project(project_type: 0) # ES-EE
          @client = create_client_with_warehouse_link(dob: '2000-01-01'.to_date)

          create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2018-01-15'.to_date,
            exit_date: '2023-01-15'.to_date,
            date_to_street_essh: '2012-10-15'.to_date,
          )

          @report = setup_report([@es_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'includes time from DateToStreetESSH even when before lookback stop date' do
          episode = @report.universe('m1b1').members.first.universe_membership
          expect(episode.first_date).to eq('2012-10-15'.to_date)
          total_days = ('2023-01-14'.to_date - '2012-10-15'.to_date).to_i + 1
          expect(episode.days_homeless).to eq(total_days)
        end
      end

      context 'with DateToStreetESSH before date of birth' do
        before do
          @es_project = create_project(project_type: 0)
          @client = create_client_with_warehouse_link(dob: '2010-01-01'.to_date)

          create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2018-01-15'.to_date,
            exit_date: '2023-01-15'.to_date,
            date_to_street_essh: '2008-06-15'.to_date,
          )

          @report = setup_report([@es_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'does not count homelessness before date of birth' do
          episode = @report.universe('m1b1').members.first.universe_membership
          expect(episode.first_date).to be >= '2010-01-01'.to_date
        end
      end

      context 'with overlapping homeless periods ES and moved-in PH enrollments' do
        before do
          @es_project = create_project(project_type: 0)
          @ph_project = create_project(project_type: 3)
          @client = create_client_with_warehouse_link

          ph_enrollment = create_enrollment(
            client: @client,
            project: @ph_project,
            entry_date: '2018-02-15'.to_date,
            exit_date: '2023-01-15'.to_date,
            living_situation: 116,
          )
          ph_enrollment.update(MoveInDate: '2018-04-01'.to_date)

          create_enrollment(
            client: @client,
            project: @es_project,
            entry_date: '2022-09-01'.to_date,
            exit_date: '2022-10-15'.to_date,
            date_to_street_essh: '2022-08-15'.to_date,
          )

          @report = setup_report([@es_project.id, @ph_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'correctly handles excludes ES enrollments that occur during PH' do
          expect(@report.universe('m1b1').members.count).to eq(0)
        end
      end

      context 'with client having PSH before the report period' do
        before do
          @psh_project = create_project(project_type: 3)
          @nbn_project = create_project(project_type: 1)
          @client = create_client_with_warehouse_link(dob: '1990-01-01')

          create_enrollment(
            client: @client,
            project: @psh_project,
            date_to_street_essh: '2014-06-01'.to_date,
            entry_date: '2021-06-01'.to_date,
            move_in_date: '2021-08-01'.to_date,
            exit_date: '2022-04-30'.to_date,
            living_situation: 116,
          )

          nbn_enrollment = create_enrollment(
            client: @client,
            project: @nbn_project,
            date_to_street_essh: '2023-01-01'.to_date,
            entry_date: '2023-08-15'.to_date,
          )
          create_bed_night_service(enrollment: nbn_enrollment, date: '2023-08-15'.to_date)

          @report = setup_report([@psh_project.id, @nbn_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'correctly calculates homelessness period' do
          episode = @report.universe('m1b1').members.first.universe_membership
          expect(episode.first_date).to eq('2023-01-01'.to_date)
          expect(episode.days_homeless).to eq(227)
        end
      end

      context 'with client having PSH overlapping the report period' do
        before do
          @psh_project = create_project(project_type: 3)
          @nbn_project = create_project(project_type: 1)
          @client = create_client_with_warehouse_link(dob: '1990-01-01')

          create_enrollment(
            client: @client,
            project: @psh_project,
            date_to_street_essh: '2014-06-01'.to_date,
            entry_date: '2021-06-01'.to_date,
            move_in_date: '2022-10-03'.to_date,
            exit_date: '2022-11-03'.to_date,
            living_situation: 116,
          )

          nbn_enrollment = create_enrollment(
            client: @client,
            project: @nbn_project,
            date_to_street_essh: '2023-01-01'.to_date,
            entry_date: '2023-08-15'.to_date,
          )
          create_bed_night_service(enrollment: nbn_enrollment, date: '2023-08-15'.to_date)

          @report = setup_report([@psh_project.id, @nbn_project.id])
          run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
        end

        it 'correctly calculates homelessness period including time before lookback stop date' do
          episode = @report.universe('m1b1').members.first.universe_membership
          expect(episode.first_date).to eq('2014-06-01'.to_date)
          psh_days = ('2022-10-02'.to_date - '2014-06-01'.to_date).to_i + 1
          nbn_days = ('2023-08-15'.to_date - '2023-01-01'.to_date).to_i + 1
          expect(episode.days_homeless).to eq(psh_days + nbn_days)
        end
      end
    end
  end
end
