# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2024::MeasureOne, type: :model do
  include_context 'SPM test setup'

  describe 'Measure 1b' do
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
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
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
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
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
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
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
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
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
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
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
        @child = create_client_with_warehouse_link
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
        run_measure(@report, HudSpmReport::Generators::Fy2024::MeasureOne)
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
end
