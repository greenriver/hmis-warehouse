require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionThree, type: :model do
  # NOTE: The date range of the report is limited and will not include everyone in the import file
  describe 'project data quality' do
    before(:all) do
      import_fixture
    end
    after(:all) do
      cleanup_fixture
    end

    describe 'a single project report' do
      let(:report) { create :data_quality_report_version_three, :single_project }
      let(:project) { report.project }
      let(:range) { ::Filters::DateRange.new(start: report.start, end: report.end) }

      it 'loads clients with enrollments open during the report range' do
        open_enrollments = GrdaWarehouse::Hud::Enrollment.open_during_range(range).where(ProjectID: report.project.ProjectID).count
        expect(report.clients.count).to eq 90
        expect(report.clients.count).to eq open_enrollments
      end

      it 'loads the same clients by project' do
        clients_ids = report.clients.map{|client| client[:id]}.uniq
        project_clients = report.clients_for_project(project.id).map{|client| client[:id]}.uniq

        expect(project_clients.count).to eq 88
        expect(clients_ids).to match_array project_clients
      end

      describe 'when looking at universal elements' do
        before do
          report.start_report()
          report.calculate_missing_universal_elements()
        end

        it 'has the appropriate number of total clients' do
          count = report.report['total_clients']

          open_enrollments = GrdaWarehouse::Hud::Enrollment.open_during_range(range).where(ProjectID: report.project.ProjectID).distinct.select(:PersonalID).count
          expect(count).to eq 88
          expect(count).to eq open_enrollments
        end

        it 'has the appropriate number of missing names' do
          count = report.report['missing_name']
           expect(count).to eq 35

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          # A field is missing if the DQ is 99 or empty, even if the field itself contains data
          missing = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              NameDataQuality: [99, nil, '']
          ).
          pluck(:id)
          missing += GrdaWarehouse::Hud::Client.where(
              id: client_ids, FirstName: [nil, '']
          ).
          where.not(NameDataQuality: 9).pluck(:id)
          missing += GrdaWarehouse::Hud::Client.where(
              id: client_ids, LastName: [nil, '']
          ).
          where.not(NameDataQuality: 9).pluck(:id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of refused names' do
          count = report.report['refused_name']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          refused = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              NameDataQuality: 9
          ).
              pluck(:id)
          expect(count).to eq refused.uniq.count
        end

        it 'has the appropriate number of missing dob' do
          # Excludes refused
          count = report.report['missing_dob']
          expect(count).to eq 33

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              DOBDataQuality: [99, nil, '']
          ).
          pluck(:id)
          missing += GrdaWarehouse::Hud::Client.where(
              id: client_ids, DOB: [nil, '']
          ).
              where.not(DOBDataQuality: 9).pluck(:id)

          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of refused dob' do
          count = report.report['refused_dob']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          refused = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              DOBDataQuality: 9
          ).
              pluck(:id)
          expect(count).to eq refused.uniq.count
        end

        it 'has the appropriate number of missing ssn' do
          # Excludes refused
          count = report.report['missing_ssn']
          expect(count).to eq 67

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::Hud::Client.where(
            id: client_ids,
            SSNDataQuality: [99, nil, '']
          ).
          pluck(:id)
          missing += GrdaWarehouse::Hud::Client.where(
            id: client_ids, SSN: [nil, '']
          ).
          where.not(SSNDataQuality: 9).pluck(:id)

          expect(count).to eq missing.uniq.count
        end


        it 'has the appropriate number of refused ssn' do
          count = report.report['refused_ssn']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          refused = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              SSNDataQuality: 9
          ).
              pluck(:id)
          expect(count).to eq refused.uniq.count
        end


        it 'has the appropriate number of clients with missing race' do
          count = report.report['missing_race']
          expect(count).to eq 65

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              RaceNone: [99]
          ).
          pluck(:id)
          missing += GrdaWarehouse::Hud::Client.where(
              id: client_ids, AmIndAKNative: [0, 99, nil, ''],
              Asian: [0, 99, nil, ''],
              BlackAfAmerican: [0, 99, nil, ''],
              NativeHIOtherPacific: [0, 99, nil, ''],
              White: [0, 99, nil, '']
          ).
          where.not(RaceNone: 9).
          pluck(:id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of refused race' do
          count = report.report['refused_race']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          refused = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              RaceNone: 9
          ).
              pluck(:id)
          expect(count).to eq refused.uniq.count
        end

        it 'has the appropriate number of clients with missing ethnicity' do
          count = report.report['missing_ethnicity']
          expect(count).to eq 60

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              Ethnicity: [99, nil, '']
          ).
          pluck(:id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of refused ethnicity' do
          count = report.report['refused_race']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          refused = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              Ethnicity: 9
          ).
              pluck(:id)
          expect(count).to eq refused.uniq.count
        end

        it 'has the appropriate number of clients with missing gender' do
          count = report.report['missing_gender']
          expect(count).to eq 5

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              Gender: [99, nil, '']
          ).
          pluck(:id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of refused gender' do
          count = report.report['refused_gender']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          refused = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              Gender: 9
          ).
              pluck(:id)
          expect(count).to eq refused.uniq.count
        end

        it 'has the appropriate number of clients with missing veteran status' do
          count = report.report['missing_veteran']
          expect(count).to eq 46

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          eighteen = report.start - 18.years
          c_t = GrdaWarehouse::Hud::Client.arel_table
          missing = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              VeteranStatus: [99, nil, '']
          ).
          where( c_t[:DOB].lteq(eighteen).or(c_t[:DOB].eq('')).or(c_t[:DOB].eq(nil)) ).
          pluck(:id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of refused veteran status' do
          count = report.report['refused_veteran']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          eighteen = report.start - 18.years
          c_t = GrdaWarehouse::Hud::Client.arel_table
          refused = GrdaWarehouse::Hud::Client.where(
              id: client_ids,
              VeteranStatus: 9
          ).
              where( c_t[:DOB].lteq(eighteen).or(c_t[:DOB].eq('')).or(c_t[:DOB].eq(nil)) ).
              pluck(:id)
          expect(count).to eq refused.uniq.count
        end
      end

      describe 'when looking at missing enrollment elements' do
        before do
          report.start_report
          report.add_missing_enrollment_elements
        end

        it 'has the appropriate number of clients with missing disabling condition' do
          count = report.report['missing_disabling_condition']
          expect(count).to eq 87

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::ServiceHistoryEnrollment.entry.
            joins(enrollment: :client).
            where(
              client_id: client_ids,
              Enrollment: {DisablingCondition: [99, nil, '']}
            ).
            pluck(:client_id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of clients with refused disabling condition' do
          count = report.report['refused_disabling_condition']
          expect(count).to eq 1

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::ServiceHistoryEnrollment.entry.
              joins(enrollment: :client).
              where(
                  client_id: client_ids,
                  Enrollment: {DisablingCondition: 9}
              ).
              pluck(:client_id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of clients with missing living situation' do
          count = report.report['missing_prior_living_situation']
          expect(count).to eq 87

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::ServiceHistoryEnrollment.entry.
              joins(enrollment: :client).
              where(
                  client_id: client_ids,
                  Enrollment: {LivingSituation: [99, nil, '']}
              ).
              pluck(:client_id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of clients with refused living situation' do
          count = report.report['refused_prior_living_situation']
          expect(count).to eq 2

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::ServiceHistoryEnrollment.entry.
              joins(enrollment: :client).
              where(
                  client_id: client_ids,
                  Enrollment: {LivingSituation: 9}
              ).
              pluck(:client_id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of clients with missing income at entry' do
          count = report.report['missing_income_at_entry']
          expect(count).to eq 1

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::ServiceHistoryEnrollment.
              includes(enrollment: :income_benefits).
              references(enrollment: :income_benefits).
              merge(GrdaWarehouse::Hud::IncomeBenefit.at_entry.all_sources_missing).
              where(
                  client_id: client_ids,
              ).
              pluck(:client_id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of clients with missing income at exit' do
          count = report.report['missing_income_at_exit']
          expect(count).to eq 1

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::ServiceHistoryEnrollment.
              includes(enrollment: :income_benefits).
              references(enrollment: :income_benefits).
              merge(GrdaWarehouse::Hud::IncomeBenefit.at_exit.all_sources_missing).
              where(
                  client_id: client_ids,
              ).
              pluck(:client_id)
          expect(count).to eq missing.uniq.count
        end

        it 'has the appropriate number of clients with missing destinations at exit' do
          count = report.report['missing_destination']
          expect(count).to eq 1

          client_ids = report.clients.map{|client| client[:destination_id]}.uniq
          missing = GrdaWarehouse::ServiceHistoryEnrollment.exit.
              where(
                  client_id: client_ids,
                  destination: [99, nil, '']
              ).
              pluck(:client_id)
          expect(count).to eq missing.uniq.count
        end
      end
    end

    describe 'a project group report' do
      let(:report) { create :data_quality_report_version_three, :project_group }

      it 'loads all projects' do
        expect(report.projects.count).to eq 3
      end

      it 'loads all clients' do
        expect(report.clients.map{|m| m[:id] }.uniq.count).to eq 110
      end
    end
  end

  def import_fixture
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :s3)
    warehouse_ds = GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    @file_path = 'spec/fixtures/files/importers/hmis_six_on_one/project_data_quality'
    @source_file_path = File.join(@file_path, 'source')
    @import_path = File.join(@file_path, @data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(@source_file_path, @import_path)

    importer = Importers::HMISSixOneOne::Base.new(file_path: @file_path, data_source_id: @data_source.id, remove_files: false)
    importer.import!
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::CalculateProjectTypes.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Update.new(force_sequential_processing: true).run!
    Delayed::Worker.new.work_off(2)
  end

  def cleanup_fixture
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    FileUtils.rm_rf(@import_path) unless @import_path == @file_path
  end

end