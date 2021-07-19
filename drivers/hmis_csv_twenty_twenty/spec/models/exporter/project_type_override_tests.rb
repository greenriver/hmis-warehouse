RSpec.shared_context '2020 project type override tests', shared_context: :metadata do
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
    describe 'when exporting enrollments' do
      before(:each) do
        enrollment_exporter.export_enrollments
        @enrollment_class = HmisCsvTwentyTwenty::Exporter::Enrollment
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
      it 'ProjectType in project does not equal override' do
        expect(projects.first.ProjectType).not_to eq projects.first.computed_project_type
      end
      it 'project type override is a type of PH' do
        expect(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]).to include(projects.first.computed_project_type)
      end
      it 'MoveInDate is set in the enrollment' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @enrollment_class), headers: true)
        expect(csv.first['MoveInDate']).not_to be_empty
      end
      it 'MoveInDate is set in the enrollment' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @enrollment_class), headers: true)
        expect(csv.first['MoveInDate']).to eq csv.first['EntryDate']
      end
    end
  end
  describe 'when override is to ES' do
    before(:each) do
      project_exporter.create_export_directory
      project_exporter.set_time_format
      project_exporter.setup_export

      @project = projects.first
      @project.update(ProjectType: 13)
      @project.update(computed_project_type: 1)
      @project_es = projects.second
      @project_es.update(computed_project_type: 1)
      @project_es.update(TrackingMethod: 3)

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

    it 'initial project setup is as expected' do
      aggregate_failures 'checking project' do
        expect(@project.ProjectType).to_not eq 1
        expect(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es]).to include(@project.computed_project_type)
        expect(@project.TrackingMethod).to be_nil
        expect(projects.count).to eq 5
      end
    end
    it 'sets tracking method in the export file' do
      csv = CSV.read(csv_file_path(project_exporter, @project_class), headers: true)
      aggregate_failures 'checking exported project' do
        project = csv.detect { |p| p['ProjectID'] == @project.id.to_s }
        expect(project['TrackingMethod']).to_not be_empty
        expect(project['TrackingMethod']).to eq '0'
      end
    end
    it 'if the tracking method is 3 it is not overridden' do
      csv = CSV.read(csv_file_path(project_exporter, @project_class), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project_es.id.to_s }
      aggregate_failures 'checking exported project' do
        expect(project['TrackingMethod']).to_not be_empty
        expect(project['TrackingMethod']).to eq '3'
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2020 project type override tests', include_shared: true
end
