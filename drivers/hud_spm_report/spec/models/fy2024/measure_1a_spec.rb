# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2024::MeasureOne, type: :model do
  include_context 'SPM test setup'

  describe 'Measure 1a' do
    context 'with single client/single enrollment' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
          date_to_street_essh: '2022-10-15'.to_date, # This won't be used in 1a
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
      end

      it 'creates SpmEnrollment records correctly' do
        expect(@report.spm_enrollments.count).to be > 0

        spm_enrollment = @report.spm_enrollments.first
        expect(spm_enrollment.entry_date).to eq('2022-11-01'.to_date)
        expect(spm_enrollment.exit_date).to eq('2023-01-15'.to_date)
      end

      it 'correctly calculates the length of time homeless without prior living situation' do
        # Verify that the universe was created for measure 1a
        expect(@report.universe('m1a1').members.count).to eq(1)

        # Verify that the appropriate metrics were calculated
        answer_b1 = @report.answer(question: '1a', cell: 'B1')
        answer_d1 = @report.answer(question: '1a', cell: 'D1')
        answer_g1 = @report.answer(question: '1a', cell: 'G1')

        # Should have a count of 1 person
        expect(answer_b1.summary.to_i).to eq(1)

        # Should have calculated the average length of time
        expect(answer_d1.summary.to_f).to be > 0

        # Should have calculated the median length of time
        expect(answer_g1.summary.to_i).to be > 0

        # Verify that the enrollment dates are used, not the self-reported date
        episode = @report.universe('m1a1').members.first.universe_membership
        expect(episode.first_date).to eq('2022-11-01'.to_date)

        # Expected days homeless: Nov 1 to Jan 14 = 75 days
        # Exit date itself is not counted as a bed night
        expect(episode.days_homeless).to eq(75)
      end
    end

    context 'with client having overlapping enrollments' do
      before do
        # Create two ES projects
        @es_project1 = create_project(project_type: 0) # ES-EE
        @es_project2 = create_project(project_type: 0) # ES-EE

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment in first ES project
        create_enrollment(
          client: @client,
          project: @es_project1,
          entry_date: '2022-10-15'.to_date,
          exit_date: '2022-12-15'.to_date,
        )

        # Create overlapping enrollment in second ES project
        create_enrollment(
          client: @client,
          project: @es_project2,
          entry_date: '2022-11-15'.to_date,
          exit_date: '2023-01-15'.to_date,
        )

        # Setup and run the report
        @report = setup_report([@es_project1.id, @es_project2.id])
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
      end

      it 'deduplicates nights when client is enrolled in multiple projects' do
        expect(@report.universe('m1a1').members.count).to eq(1)

        episode = @report.universe('m1a1').members.first.universe_membership

        # Expected days homeless:
        # Oct 15 to Jan 14 = 92 days
        # (overlapping days should only be counted once)
        expect(episode.days_homeless).to eq(92)
      end
    end

    context 'with client moving from ES to TH' do
      before do
        # Create ES and TH projects
        @es_project = create_project(project_type: 0) # ES-EE
        @th_project = create_project(project_type: 2) # TH

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment in ES project
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-10-15'.to_date,
          exit_date: '2022-11-15'.to_date,
        )

        # Create subsequent enrollment in TH project
        create_enrollment(
          client: @client,
          project: @th_project,
          entry_date: '2022-11-20'.to_date,
          exit_date: '2023-01-20'.to_date,
        )

        # Setup and run the report
        @report = setup_report([@es_project.id, @th_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
      end

      it 'correctly counts both ES and TH time for metric 2' do
        # ES-only (metric 1) should have only ES time
        expect(@report.universe('m1a1').members.count).to eq(1)
        es_episode = @report.universe('m1a1').members.first.universe_membership

        # ES+TH (metric 2) should have both ES and TH time
        expect(@report.universe('m1a2').members.count).to eq(1)
        es_th_episode = @report.universe('m1a2').members.first.universe_membership

        # Expected days in ES: Oct 15 to Nov 14 = 31 days
        expect(es_episode.days_homeless).to eq(31)

        # Expected days in ES+TH:
        # Oct 15 to Nov 14 (ES) = 31 days
        # Nov 20 to Jan 19 (TH) = 61 days
        # Total = 92 days
        expect(es_th_episode.days_homeless).to eq(92)
      end
    end

    context 'with night-by-night ES stay' do
      before do
        # Create an ES-NBN project
        @nbn_project = create_project(project_type: 1) # ES-NBN

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment
        enrollment = create_enrollment(
          client: @client,
          project: @nbn_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
        )

        # Add bed night services (sporadic, not continuous)
        create_bed_night_service(enrollment: enrollment, date: '2022-11-05'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-11-10'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-11-15'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-12-01'.to_date)
        create_bed_night_service(enrollment: enrollment, date: '2022-12-15'.to_date)

        # Setup and run the report
        @report = setup_report([@nbn_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
      end

      it 'counts only actual bed nights for night-by-night shelters' do
        expect(@report.universe('m1a1').members.count).to eq(1)

        episode = @report.universe('m1a1').members.first.universe_membership

        # Expected homeless days should include only the recorded bed nights = 5 days
        expect(episode.days_homeless).to eq(5)
      end
    end

    context 'with exit date same as another entry date' do
      before do
        # Create two ES projects
        @es_project1 = create_project(project_type: 0) # ES-EE
        @es_project2 = create_project(project_type: 0) # ES-EE

        # Create a client
        @client = create_client_with_warehouse_link

        # Create enrollment in first ES project
        create_enrollment(
          client: @client,
          project: @es_project1,
          entry_date: '2022-10-15'.to_date,
          exit_date: '2022-11-15'.to_date,
        )

        # Create enrollment in second ES project starting on the same day as exit from first
        create_enrollment(
          client: @client,
          project: @es_project2,
          entry_date: '2022-11-15'.to_date,
          exit_date: '2022-12-15'.to_date,
        )

        # Setup and run the report
        @report = setup_report([@es_project1.id, @es_project2.id])
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
      end

      it 'correctly handles exit dates that match entry dates' do
        expect(@report.universe('m1a1').members.count).to eq(1)

        episode = @report.universe('m1a1').members.first.universe_membership

        # Expected days homeless:
        # Oct 15 to Dec 14 = 61 days
        # (exit date of first enrollment should not be counted as a bed night,
        # but entry date of second enrollment should be)
        expect(episode.days_homeless).to eq(61)
      end
    end

    context 'with client having zero-day stays' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create a client
        @client = create_client_with_warehouse_link

        # Create a zero-day enrollment (entry and exit on same day)
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-11-15'.to_date,
          exit_date: '2022-11-15'.to_date,
        )

        # Create a regular enrollment
        create_enrollment(
          client: @client,
          project: @es_project,
          entry_date: '2022-12-01'.to_date,
          exit_date: '2022-12-15'.to_date,
        )

        # Setup and run the report
        @report = setup_report([@es_project.id])
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
      end

      it 'excludes zero-day stays from homeless days count' do
        expect(@report.universe('m1a1').members.count).to eq(1)

        episode = @report.universe('m1a1').members.first.universe_membership

        # Expected days homeless:
        # Dec 1 to Dec 14 = 14 days
        # (the zero-day stay should not add any days)
        expect(episode.days_homeless).to eq(14)
      end
    end
  end
end
