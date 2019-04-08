RSpec.shared_context "project type override tests", shared_context: :metadata do
  describe 'When exporting enrollment related item' do
    before(:each) do
      exporter.create_export_directory()
      exporter.set_time_format()
      exporter.setup_export()
    end
    after(:each) do
      exporter.remove_export_files()
      exporter.reset_time_format()
      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryGirl.reload
    end
    describe 'when exporting enrollments' do
      before(:each) do
        exporter.export_enrollments()
        @enrollment_class = GrdaWarehouse::Export::HMISSixOneOne::Enrollment
      end
      it 'enrollment scope should find one enrollment' do
        expect( exporter.enrollment_scope.count ).to eq 1
      end
      it 'creates one CSV file' do
        expect(File.exists?(csv_file_path(@enrollment_class))).to be true
      end
      it 'adds one row to the enrollment CSV file' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.count).to eq 1
      end
      it 'EnrollmentID from CSV file match the id of first enrollment' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.first['EnrollmentID']).to eq enrollments.first.id.to_s
      end
      it 'ProjectType in project does not equal override' do
        expect(projects.first.ProjectType).not_to eq projects.first.act_as_project_type
      end
      it 'project type override is a type of PH' do
        expect(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]).to include(projects.first.act_as_project_type)
      end
      it 'MoveInDate is set in the enrollment' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.first['MoveInDate']).not_to be_empty
      end
      it 'MoveInDate is set in the enrollment' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.first['MoveInDate']).to eq csv.first['EntryDate']
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context "project type override tests", include_shared: true
end