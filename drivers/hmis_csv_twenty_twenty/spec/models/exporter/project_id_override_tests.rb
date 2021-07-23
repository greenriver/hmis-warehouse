RSpec.shared_context '2020 project id override tests', shared_context: :metadata do
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
    {
      enrollment_cocs: {
        export_method: :export_enrollment_cocs,
        export_class: HmisCsvTwentyTwenty::Exporter::EnrollmentCoc,
      },
    }.each do |k, options|
      describe "when exporting #{k}" do
        before(:each) do
          enrollment_exporter.public_send(options[:export_method])
          @exported_class = options[:export_class]
        end
        it 'enrollment scope should find one enrollment' do
          expect(enrollment_exporter.enrollment_scope.count).to eq 1
        end
        it 'creates one CSV file' do
          expect(File.exist?(csv_file_path(enrollment_exporter, @exported_class))).to be true
        end
        it "adds one row to the #{options[:export_class].name} CSV file" do
          csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
          expect(csv.count).to eq 1
        end
        it 'ProjectID from CSV matches ProjectID from EnrollmentCoC' do
          csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
          # Note, by the time this gets exported, it is re-written to the project.id
          expect(csv.first['ProjectID']).to eq projects.first.id.to_s
        end
      end
    end

    describe 'when Project ID is missing' do
      {
        enrollment_cocs: {
          export_method: :export_enrollment_cocs,
          export_class: HmisCsvTwentyTwenty::Exporter::EnrollmentCoc,
        },
      }.each do |k, options|
        describe "when exporting #{k}" do
          before(:each) do
            @exported_class = options[:export_class]
            @exported_class.update_all(ProjectID: nil)
            enrollment_exporter.public_send(options[:export_method])
          end

          after(:each) do
            # The enrollments and project sequences seem to drift.
            # This ensures we'll have one to test
            FactoryBot.reload
          end

          it "adds one row to the #{options[:export_class].name} CSV file" do
            csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
            expect(csv.count).to eq 1
          end
          it 'ProjectID from CSV matches ProjectID from Enrollment' do
            csv = CSV.read(csv_file_path(enrollment_exporter, @exported_class), headers: true)
            expect(csv.first['ProjectID']).to eq projects.first.id.to_s
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2020 project id override tests', include_shared: true
end
