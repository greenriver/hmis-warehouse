RSpec.shared_context "multi-project tests", shared_context: :metadata do
  describe 'When exporting project related item' do
    before(:each) do
      exporter.create_export_directory()
      exporter.set_time_format()
      exporter.setup_export()
    end
    after(:each) do
      exporter.remove_export_files()
      exporter.reset_time_format()
    end
    describe 'when exporting projects' do
      before(:each) do
        exporter.export_projects()
        @project_class = GrdaWarehouse::Export::HMISSixOneOne::Project
      end
      it 'project scope should find five projects' do
        expect( exporter.project_scope.count ).to eq 5
      end
      it 'creates one CSV file' do
        expect(File.exists?(csv_file_path(@project_class))).to be true
      end
      it 'adds five rows to the project CSV file' do
        csv_projects = CSV.read(csv_file_path(@project_class), headers: true)
        expect(csv_projects.count).to eq 5
      end
      it 'project from CSV file should contain all project names' do
        csv = CSV.read(csv_file_path(@project_class), headers: true)
        csv_project_names = csv.map{|m| m['ProjectName']}
        expect(csv_project_names).to eq projects.map(&:ProjectName)
      end
      it 'ProjectID from CSV should contain all project IDs' do
        csv = CSV.read(csv_file_path(@project_class), headers: true)
        csv_project_ids = csv.map{|m| m['ProjectID']}
        expect(csv_project_ids).to eq projects.map(&:id).map(&:to_s)
      end
    end
    ProjectRelatedTests::TESTS.each do |item|
      describe "when exporting #{item[:list]}" do
        before(:each) do
          exporter.public_send(item[:export_method])
        end
        it "creates one #{item[:klass].file_name} CSV file" do
          expect(File.exists?(csv_file_path(item[:klass]))).to be true
        end
        it "adds five rows to the #{item[:klass].file_name} CSV file" do
          csv = CSV.read(csv_file_path(item[:klass]), headers: true)
          expect(csv.count).to eq 5
        end
        it "hud keys in CSV should match source data" do
          csv = CSV.read(csv_file_path(item[:klass]), headers: true)
          current_hud_key = item[:klass].clean_headers([item[:klass].hud_key]).first.to_s
          csv_keys = csv.map{|m| m[current_hud_key]}
          source_keys = send(item[:list]).map(&:id).map(&:to_s)
          expect(csv_keys).to eq source_keys
        end
        if item[:klass].column_names.include?('ProjectID')
          it 'ProjectIDs from CSV file match project ids' do
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            csv_project_ids = csv.map{|m| m['ProjectID']}
            source_ids = projects.map(&:id).map(&:to_s)
            expect(csv_project_ids).to eq source_ids
          end
        end
        
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context "multi-project tests", include_shared: true
end