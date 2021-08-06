require 'rails_helper'
include ArelHelper

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFour, type: :model do
  # NOTE: The date range of the report is limited and will not include everyone in the import file
  describe 'project data quality V4' do
    before(:all) do
      import_hmis_csv_fixture(
        'spec/fixtures/files/importers/hmis_twenty_twenty/project_data_quality_v4',
        version: 'AutoDetect',
      )
    end
    after(:all) do
      cleanup_hmis_csv_fixtures
    end

    describe 'a single project report' do
      before(:all) do
        @report = create :data_quality_report_version_four, :single_project
        @project = @report.project
        @range = ::Filters::DateRange.new(start: @report.start, end: @report.end)
        @report.run!
      end
      after(:all) do
      end
      it 'loads clients with enrollments open during the report range' do
        open_enrollments = included_enrollments.distinct.select(:PersonalID).count

        client_count = @report.source_enrollments.distinct.select(:PersonalID).count

        aggregate_failures 'checking counts' do
          expect(client_count).to eq 92
          expect(client_count).to eq open_enrollments
        end
      end

      it 'creates equivalent report_enrollments' do
        open_enrollments = included_enrollments.distinct.select(:EnrollmentID).count

        report_enrollments = @report.enrollments.count
        expect(open_enrollments).to eq report_enrollments
      end

      it 'name refused' do
        key = :name
        enrollment_count = @report.enrollments.where(name_refused: true).count
        enrollment_denominator = @report.enrollments.count

        source_client_count = enrolled_clients.where(NameDataQuality: [8, 9]).count

        report_percentages = @report.project_completeness(hud_project: @project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]["Don't Know / Refused"][index]
        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 2
          expect(enrollment_count).to eq source_client_count

          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'name not collected' do
        key = :name
        enrollment_count = @report.enrollments.where(name_not_collected: true).count
        enrollment_denominator = @report.enrollments.count

        source_client_count = enrolled_clients.where(NameDataQuality: [99]).count

        report_percentages = @report.project_completeness(hud_project: @project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]['Not Collected'][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 2
          expect(enrollment_count).to eq source_client_count

          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'ssn refused' do
        key = :ssn
        enrollment_count = @report.enrollments.where(ssn_refused: true).count
        enrollment_denominator = @report.enrollments.count

        source_client_count = enrolled_clients.where(SSNDataQuality: [8, 9]).count

        report_percentages = @report.project_completeness(hud_project: @project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]["Don't Know / Refused"][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 3
          expect(enrollment_count).to eq source_client_count

          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'ssn not collected' do
        key = :ssn
        enrollment_count = @report.enrollments.where(ssn_not_collected: true).count
        enrollment_denominator = @report.enrollments.count

        source_client_count = enrolled_clients.where(SSNDataQuality: [99]).count

        report_percentages = @report.project_completeness(hud_project: @project)
        index = report_percentages[:columns].index(key)
        report_percentage = report_percentages[:data]['Not Collected'][index]

        aggregate_failures 'checking counts' do
          expect(source_client_count).to eq 63
          expect(enrollment_count).to eq source_client_count

          expect(((enrollment_count / enrollment_denominator.to_f) * 100).round).to eq report_percentage
        end
      end

      it 'exiting clients' do
        aggregate_failures 'checking counts' do
          expect(exiting_clients.count).to eq @report.enrollments.exited.count
          expect(exiting_clients.pluck(:id).sort).to eq @report.enrollments.exited.pluck(:client_id).sort
        end
      end

      it 'exits to ph' do
        source_clients = exiting_clients.where(ex_t[:Destination].in(HUD.permanent_destinations))
        exits = @report.enrollments.exited.where(destination_id: HUD.permanent_destinations)
        expect(source_clients.count).to eq exits.count
      end

      it 'no service in the past month' do
        source_with_service_count = enrolled_clients.
          joins(:services).
          merge(
            GrdaWarehouse::Hud::Service.where(DateProvided: (@range.end - 30.days..@range.end)),
          ).
          distinct.
          count
        with_service_count = @report.enrollments.where(service_within_last_30_days: true).count
        expect(source_with_service_count).to eq with_service_count
      end
    end

    def included_enrollments
      GrdaWarehouse::Hud::Enrollment.
        open_during_range(@range).
        where(ProjectID: @report.project.ProjectID)
    end

    def enrolled_clients
      GrdaWarehouse::Hud::Client.joins(:enrollments).
        merge(
          GrdaWarehouse::Hud::Enrollment.open_during_range(@range).
            where(ProjectID: @report.project.ProjectID),
        )
    end

    def exiting_clients
      GrdaWarehouse::Hud::Client.joins(enrollments: :exit).
        merge(
          GrdaWarehouse::Hud::Enrollment.open_during_range(@range).
            where(ProjectID: @report.project.ProjectID),
        ).
        merge(
          GrdaWarehouse::Hud::Exit.where(ExitDate: @range.range),
        )
    end
  end
end
