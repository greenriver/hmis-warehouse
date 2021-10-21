RSpec.shared_context '2022 project coc zip override tests', shared_context: :metadata do
  describe 'When exporting' do
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
    describe 'Project CoC records' do
      before(:each) do
        enrollment_exporter.export_project_cocs
        @export_class = HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc
      end
      it 'adds one row to the ProjectCoC CSV file' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @export_class), headers: true)
        expect(csv.count).to eq 1
      end
      it 'Zip from CSV file matches the first ProjectCoC Zip' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @export_class), headers: true)
        expect(csv.first['Zip']).to eq project_cocs.first.Zip
      end
    end

    describe 'when override is present' do
      before(:each) do
        @zip = '05301'
        @export_class = HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc
        GrdaWarehouse::Hud::ProjectCoc.update_all(zip_override: @zip)
        enrollment_exporter.export_project_cocs
      end
      it 'adds one row to the ProjectCoC CSV file' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @export_class), headers: true)
        expect(csv.count).to eq 1
      end
      it 'Zip from CSV file matches the first ProjectCoC zip_override' do
        csv = CSV.read(csv_file_path(enrollment_exporter, @export_class), headers: true)
        expect(csv.first['Zip']).to eq @zip
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 project coc zip override tests', include_shared: true
end
