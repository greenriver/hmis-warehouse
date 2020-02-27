require 'rails_helper'
include ArelHelper

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFour, type: :model do
  # NOTE: The date range of the report is limited and will not include everyone in the import file
  describe 'project data quality V4' do
    before(:all) do
      import_fixture
    end
    after(:all) do
      cleanup_fixture
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

  def import_fixture
    cleanup_fixture
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :s3)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    @file_path = 'spec/fixtures/files/importers/hmis_twenty_twenty/project_data_quality_v4'
    @source_file_path = File.join(@file_path, 'source')
    @import_path = File.join(@file_path, @data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(@source_file_path, @import_path)

    importer = Importers::HMISSixOneOne::Base.new(file_path: @file_path, data_source_id: @data_source.id, remove_files: false)
    importer.import!
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.unprocessed.pluck(:id).each_slice(250) do |batch|
      Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch), queue: :low_priority)
    end
    Delayed::Worker.new.work_off(2)
  end

  def cleanup_fixture
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    FileUtils.rm_rf(@import_path) unless @import_path == @file_path
  end
end
