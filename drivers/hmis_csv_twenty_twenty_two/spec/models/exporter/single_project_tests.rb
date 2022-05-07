###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 single-project tests', shared_context: :metadata do
  describe 'when exporting projects' do
    it 'project scope should find one project' do
      expect(@exporter.project_scope.count).to eq 1
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
      expect(csv_projects.first['ProjectName']).to eq @projects.first.ProjectName
    end
    it 'ProjectID from CSV file match the id of first project' do
      csv_projects = CSV.read(csv_file_path(@project_class), headers: true)
      expect(csv_projects.first['ProjectID']).to eq @projects.first.id.to_s
    end
  end

  project_classes.each do |klass|
    describe "when exporting #{klass}" do
      it "creates one #{klass.hud_csv_file_name} CSV file" do
        expect(File.exist?(csv_file_path(klass))).to be true
      end
      it "adds one row to the #{klass.hud_csv_file_name} CSV file" do
        csv = CSV.read(csv_file_path(klass), headers: true)
        expect(csv.count).to eq 1
      end
      it 'hud key in CSV should match id of first item in list' do
        csv = CSV.read(csv_file_path(klass), headers: true)
        hmis_class = klass.hmis_class
        expect(csv.first[hmis_class.hud_key.to_s]).to eq hmis_class.first.id.to_s
      end
      if klass.hmis_class.column_names.include?('ProjectID')
        it 'ProjectID from CSV file match the id of first project' do
          csv = CSV.read(csv_file_path(klass), headers: true)
          expect(csv.first['ProjectID']).to eq @projects.first.id.to_s
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 single-project tests', include_shared: true
end
