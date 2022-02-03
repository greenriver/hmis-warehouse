###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 project continuum override tests', shared_context: :metadata do
  describe 'When exporting enrollment related item' do
    before(:each) do
      exporter.create_export_directory
      exporter.set_time_format
      exporter.setup_export
    end
    after(:each) do
      exporter.remove_export_files
      exporter.reset_time_format
      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryBot.reload
    end
    describe 'when exporting enrollments' do
      before(:each) do
        projects[0].update(ContinuumProject: 0, hud_continuum_funded: nil)
        projects[1].update(ContinuumProject: 0, hud_continuum_funded: true)
        projects[2].update(ContinuumProject: 0, hud_continuum_funded: false)
        projects[3].update(ContinuumProject: 1, hud_continuum_funded: nil)
        projects[4].update(ContinuumProject: 1, hud_continuum_funded: true)
        projects[5].update(ContinuumProject: 1, hud_continuum_funded: false)

        exporter.export_projects
        @project_class = HmisCsvTwentyTwentyTwo::Exporter::Project
      end
      it 'creates a CSV file' do
        expect(File.exist?(csv_file_path(@project_class))).to be true
      end
      it 'adds 5 rows to the project CSV file' do
        csv = CSV.read(csv_file_path(@project_class), headers: true)
        expect(csv.count).to eq 6
      end
      it 'no override for 2 projects' do
        expect(projects.select { |m| m.hud_continuum_funded.nil? }.count).to eq 2
      end
      it 'true override for 2 projects' do
        expect(projects.select { |m| m.hud_continuum_funded == true }.count).to eq 2
      end
      it 'false override for 2 projects' do
        expect(projects.select { |m| m.hud_continuum_funded == false }.count).to eq 2
      end
      it 'exported file to have 3 ContinuumProject: 0' do
        csv = CSV.read(csv_file_path(@project_class), headers: true)
        zeros = csv.select do |row|
          row['ContinuumProject'] == '0'
        end
        expect(zeros.count).to eq 3
      end
      it 'exported file to have 3 ContinuumProject: 0' do
        csv = CSV.read(csv_file_path(@project_class), headers: true)
        ones = csv.select do |row|
          row['ContinuumProject'] == '1'
        end
        expect(ones.count).to eq 3
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 project continuum override tests', include_shared: true
end
