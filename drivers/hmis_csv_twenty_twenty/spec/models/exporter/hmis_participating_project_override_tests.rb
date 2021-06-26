RSpec.shared_context '2020 HMIS Participating Project override tests', shared_context: :metadata do
  describe 'When exporting enrollment related item' do
    before(:each) do
      enrollment_exporter.create_export_directory
      enrollment_exporter.set_time_format
      enrollment_exporter.setup_export
    end
    after(:each) do
      enrollment_exporter.remove_export_files
      enrollment_exporter.reset_time_format

      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryBot.reload
    end
    describe 'when exporting' do
      before(:each) do
        enrollment_exporter.export_enrollments
        enrollment_exporter.export_projects
        @enrollment_class = HmisCsvTwentyTwenty::Exporter::Enrollment
        @project_class = HmisCsvTwentyTwenty::Exporter::Project
      end
      it 'enrollment scope should find one enrollment' do
        expect(enrollment_exporter.enrollment_scope.count).to eq 1
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(enrollment_exporter, @enrollment_class))).to be true
      end
      it 'adds one row to the enrollment CSV file' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @enrollment_class), headers: true)
        expect(csv.count).to eq 1
      end
      it 'EnrollmentID from CSV file match the id of first enrollment' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @enrollment_class), headers: true)
        expect(csv.first['EnrollmentID']).to eq enrollments.first.id.to_s
      end
      it 'HMISParticipatingProject in project does not equal override' do
        expect(projects.first.HMISParticipatingProject).not_to eq projects.first.hmis_participating_project_override
      end
      it 'HMIS Participating Project override is a 0' do
        expect(projects.first.hmis_participating_project_override).to eq(0)
      end
      it 'exported value matches the override' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @project_class), headers: true)
        expect(csv.first['HMISParticipatingProject']).to eq projects.first.hmis_participating_project_override.to_s
      end
    end
  end
  describe 'when override is not set' do
    before(:each) do
      project_exporter.create_export_directory
      project_exporter.set_time_format
      project_exporter.setup_export

      @project = projects.first
      @project.update(HMISParticipatingProject: nil)
      @project.update(hmis_participating_project_override: nil)
      @project_2 = projects.second
      @project_2.update(HMISParticipatingProject: 1)
      @project_2.update(hmis_participating_project_override: nil)

      project_exporter.export_projects
      @project_class = HmisCsvTwentyTwenty::Exporter::Project
    end

    after(:each) do
      project_exporter.remove_export_files
      project_exporter.reset_time_format

      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryBot.reload
    end

    it 'sets HMISParticipatingProject in the export file' do
      csv = CSV.read(csv_file_path(project_exporter, @project_class), headers: true)
      aggregate_failures 'checking exported project' do
        project = csv.detect { |p| p['ProjectID'] == @project.id.to_s }
        expect(project['HMISParticipatingProject']).to_not be_empty
        expect(project['HMISParticipatingProject']).to eq('99')
      end
    end
    it 'sets second HMISParticipatingProject in the export file' do
      csv = CSV.read(csv_file_path(project_exporter, @project_class), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project_2.id.to_s }
      aggregate_failures 'checking exported project' do
        expect(project['HMISParticipatingProject']).to_not be_empty
        expect(project['HMISParticipatingProject']).to eq '1'
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2020 HMIS Participating Project override tests', include_shared: true
end
