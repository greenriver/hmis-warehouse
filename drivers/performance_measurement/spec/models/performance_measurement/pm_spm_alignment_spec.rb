
require 'rails_helper'
require_relative './shared_context'

RSpec.describe 'Performance Measurement and SPM Alignment', type: :model do
  include_context 'SPM test setup'

  describe 'measure 1 values alignment' do
    context 'with various client scenarios' do
      before do
        PerformanceMeasurement::Goal.ensure_default
        # Create ES and TH projects
        @es_project = create_project(project_type: 0) # ES-EE
        @th_project = create_project(project_type: 2) # TH

        # Create clients with different homeless patterns
        @client1 = create_client_with_warehouse_link
        @client2 = create_client_with_warehouse_link
        @client3 = create_client_with_warehouse_link

        # Client 1: Simple ES stay
        create_enrollment(
          client: @client1,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date
        )

        # Client 2: ES stay followed by TH stay with gap
        create_enrollment(
          client: @client2,
          project: @es_project,
          entry_date: '2022-10-15'.to_date,
          exit_date: '2022-12-15'.to_date
        )

        create_enrollment(
          client: @client2,
          project: @th_project,
          entry_date: '2022-12-20'.to_date,
          exit_date: '2023-01-20'.to_date
        )

        # Client 3: Overlapping ES stays
        create_enrollment(
          client: @client3,
          project: @es_project,
          entry_date: '2022-10-01'.to_date,
          exit_date: '2022-12-01'.to_date
        )

        create_enrollment(
          client: @client3,
          project: @es_project,
          entry_date: '2022-11-15'.to_date,
          exit_date: '2023-01-15'.to_date
        )

        # Generate the service history records for these enrollments
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        # Step 1: Run the SPM report
        spm_report_filter = default_filter.dup
        spm_report_filter.update(project_ids: [@es_project.id, @th_project.id])

        @spm_report = HudReports::ReportInstance.from_filter(
          spm_report_filter,
          'System Performance Measures - FY 2024',
          build_for_questions: ['Measure 1']
        )
        @spm_report.question_names = ['Measure 1']
        @spm_report.save!

        # Generate SPM data
        HudSpmReport::Fy2024::SpmEnrollment.create_enrollment_set(@spm_report)
        generator = HudSpmReport::Generators::Fy2024::Generator.new(@spm_report)
        measure = HudSpmReport::Generators::Fy2024::MeasureOne.new(generator, @spm_report)
        measure.run_question!
        @spm_report.reload

        # Step 2: Run the Performance Measurement report with the same data
        @pm_report = PerformanceMeasurement::Report.new(
          user_id: user.id
        )
        @pm_report.filter = spm_report_filter
        @pm_report.update_goal_configuration!
        @pm_report.save!
        @pm_report.update_goal_configuration!
        @pm_report.run_and_save!
        @pm_report.reload
      end

      after(:all) do
        # Clean up
        HmisCsvImporter::Utility.clear!
        GrdaWarehouse::Utility.clear!
      end

      it 'has the same client count in both reports' do
        # SPM report universe count
        spm_client_count = @spm_report.answer(question: '1a', cell: 'B2').summary

        # PM report client count
        pm_client_count = @pm_report.result_for(:count_of_homeless_clients_in_range).primary_value

        # Both should have 3 clients
        expect(spm_client_count).to eq(3)
        expect(pm_client_count).to eq(3)
      end

      it 'has aligned average days homeless value for ES, SH and TH' do
        # SPM report average days
        spm_average = @spm_report.answer(question: '1a', cell: 'D2').summary.to_f

        # PM report average days
        pm_result = @pm_report.result_for(:length_of_homeless_time_homeless_average)
        pm_average = pm_result.primary_value.to_f

        # They should match
        expect(pm_average).to be_within(0.1).of(spm_average)
      end

      it 'has aligned median days homeless value for ES, SH and TH' do
        # SPM report median days
        spm_median = @spm_report.answer(question: '1a', cell: 'G2').summary.to_f

        # PM report median days
        pm_result = @pm_report.result_for(:length_of_homeless_time_homeless_median)
        pm_median = pm_result.primary_value.to_f

        expect(pm_median).to be_within(0.1).of(spm_median)
      end

      it 'has aligned days homeless for each client' do
        # Get the raw client data from both reports to compare

        # SPM report - get the days homeless from the episodes
        spm_episodes = @spm_report.universe('m1a2').members.map(&:universe_membership)
        spm_client_days = spm_episodes.map do |episode|
          [episode.client_id, episode.days_homeless]
        end.to_h

        # PM report - get the days homeless from the client records
        pm_clients = @pm_report.clients.where.not(reporting_days_homeless_es_sh_th: nil)
        pm_client_days = pm_clients.map do |client|
          [client.client_id, client.reporting_days_homeless_es_sh_th]
        end.to_h

        # Check if the days match for each client
        spm_client_days.each do |client_id, days|
          expect(pm_client_days[client_id]).to eq(days),
            "Client #{client_id} has #{pm_client_days[client_id]} days in PM report but #{days} days in SPM"
        end
      end

      it 'tracks client processing through add_clients method' do
        # This test will manually run a part of the process to trace how values are calculated

        # Setup a mini report to trace through data
        tracer_report = PerformanceMeasurement::Report.new(user_id: user.id)
        tracer_report.filter = default_filter.dup
        tracer_report.filter.update(project_ids: [@es_project.id, @th_project.id])
        tracer_report.update_goal_configuration!
        tracer_report.save!

        # Get the SPM report
        spm_report = @spm_report

        # Manually trace the add_clients process for a single SPM data value
        spm_fields = tracer_report.send(:spm_fields)
        measure_1_field = spm_fields.find { |f| f[:title] == 'Length of Time Homeless in ES, SH, TH' }

        # Get the members from the SPM report
        cell = measure_1_field[:cells].first
        members = tracer_report.send(:cell_members, spm_report, *cell)

        # Process client data
        report_clients = {}
        variant_name = :reporting

        # Manual calculation for each member
        members.each do |member|
          hud_client = member.client
          spm_enrollments = tracer_report.send(:spm_enrollments_from_answer_member, member)
          days_homeless = member.days_homeless

          # Check what's used for days calculation
          measure_1_field[:questions].each do |question|
            value = question[:value_calculation].call(member)
          end
        end
      end
    end
  end
end
