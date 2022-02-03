###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 multi-project tests', shared_context: :metadata do
  describe "When exporting project related items for #{project_test_type}" do
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
      it 'project scope should find three projects' do
        expect(exporter.project_scope.count).to eq 3
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(@project_class))).to be true
      end
      it 'adds three rows to the project CSV file' do
        csv_projects = CSV.read(csv_file_path(@project_class), headers: true)
        expect(csv_projects.count).to eq 3
      end
      it 'project from CSV file should contain first three project names' do
        csv = CSV.read(csv_file_path(@project_class), headers: true)
        csv_project_names = csv.map { |m| m['ProjectName'] }.sort
        source_names = GrdaWarehouse::Hud::Project.where(id: involved_project_ids).pluck(:ProjectName)
        # source_ids = projects.first(3).map(&:ProjectName).sort
        expect(csv_project_names.sort).to eq source_names.sort
      end
      it 'ProjectID from CSV should contain first three project IDs' do
        csv = CSV.read(csv_file_path(@project_class), headers: true)
        csv_project_ids = csv.map { |m| m['ProjectID'] }.sort
        source_ids = involved_project_ids.map(&:to_s).sort
        expect(csv_project_ids).to eq source_ids
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
        it "adds three rows to the #{item[:klass].hud_csv_file_name} CSV file" do
          csv = CSV.read(csv_file_path(item[:klass]), headers: true)
          expect(csv.count).to eq 3
        end
        if item[:klass].column_names.include?('ProjectID')
          it 'hud keys in CSV should match source data' do
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            current_hud_key = item[:klass].new.clean_headers([item[:klass].hud_key]).first.to_s
            csv_keys = csv.map { |m| m[current_hud_key] }.sort
            projects_project_ids = GrdaWarehouse::Hud::Project.where(id: involved_project_ids).pluck(:ProjectID)
            source_keys = send(item[:list]).select do |m|
              projects_project_ids.include? m.ProjectID
            end.map(&:id).map(&:to_s).sort
            expect(csv_keys).to eq source_keys
          end

          it 'ProjectIDs from CSV file match project ids' do
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            csv_project_ids = csv.map { |m| m['ProjectID'] }.sort
            source_ids = involved_project_ids.map(&:to_s).sort
            expect(csv_project_ids).to eq source_ids
          end
        elsif item[:klass].column_names.include?('OrganizationID')
          it 'hud keys in CSV should match source data' do
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            current_hud_key = item[:klass].new.clean_headers([item[:klass].hud_key]).first.to_s
            csv_keys = csv.map { |m| m[current_hud_key] }.sort
            projects_org_ids = GrdaWarehouse::Hud::Project.where(id: involved_project_ids).pluck(:OrganizationID)
            source_keys = send(item[:list]).select do |m|
              projects_org_ids.include? m.OrganizationID
            end.map(&:id).map(&:to_s).sort
            expect(csv_keys).to eq source_keys
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 multi-project tests', include_shared: true
end
