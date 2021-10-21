RSpec.shared_context '2022 single-project tests', shared_context: :metadata do
  describe 'When exporting project related item' do
    before(:each) do
      exporter.create_export_directory
      exporter.set_time_format
      exporter.setup_export
    end
    after(:each) do
      exporter.remove_export_files
      exporter.reset_time_format
      FactoryBot.reload
    end
    describe 'when exporting projects' do
      before(:each) do
        exporter.export_projects
        @project_class = HmisCsvTwentyTwentyTwo::Exporter::Project
      end
      it 'project scope should find one project' do
        expect(exporter.project_scope.count).to eq 1
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(@project_class))).to be true
      end
      it 'adds one row to the project CSV file' do
        csv_projects = CSV.read(csv_file_path(@project_class), headers: true)
        expect(csv_projects.count).to eq 1
      end
      it 'project from CSV file should have the same name as the first project' do
        csv_projects = CSV.read(csv_file_path(@project_class), headers: true)
        expect(csv_projects.first['ProjectName']).to eq projects.first.ProjectName
      end
      it 'ProjectID from CSV file match the id of first project' do
        csv_projects = CSV.read(csv_file_path(@project_class), headers: true)
        expect(csv_projects.first['ProjectID']).to eq projects.first.id.to_s
      end
    end
    ProjectRelatedHmisTwentyTwentyTests::TESTS.each do |item|
      describe "when exporting #{item[:list]}" do
        before(:each) do
          exporter.public_send(item[:export_method])
        end
        it "creates one #{item[:klass].hud_csv_file_name} CSV file" do
          expect(File.exist?(csv_file_path(item[:klass]))).to be true
        end
        it "adds one row to the #{item[:klass].hud_csv_file_name} CSV file" do
          csv = CSV.read(csv_file_path(item[:klass]), headers: true)
          expect(csv.count).to eq 1
        end
        it 'hud key in CSV should match id of first item in list' do
          csv = CSV.read(csv_file_path(item[:klass]), headers: true)
          current_hud_key = item[:klass].new.clean_headers([item[:klass].hud_key]).first.to_s
          expect(csv.first[current_hud_key]).to eq send(item[:list]).first.id.to_s
        end
        if item[:klass].column_names.include?('ProjectID')
          it 'ProjectID from CSV file match the id of first project' do
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            expect(csv.first['ProjectID']).to eq projects.first.id.to_s
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 single-project tests', include_shared: true
end
