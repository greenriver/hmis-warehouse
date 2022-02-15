###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 confidential tests', shared_context: :metadata do
  describe 'Project and organization non-confidential items' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
    end
    before(:each) do
      FactoryBot.reload
      non_confidential.create_export_directory
      non_confidential.set_time_format
      non_confidential.setup_export
    end
    after(:each) do
      non_confidential.remove_export_files
      non_confidential.reset_time_format
      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryBot.reload
    end
    [
      [
        :non_confidential,
        {
          export_method: :export_projects,
          export_class: HmisCsvTwentyTwentyTwo::Exporter::Project,
          fields: ['ProjectName', 'ProjectCommonName'],
        },
      ],
      [
        :non_confidential,
        {
          export_method: :export_organizations,
          export_class: HmisCsvTwentyTwentyTwo::Exporter::Organization,
          joins: :organization,
          fields: ['OrganizationName', 'OrganizationCommonName'],
        },
      ],
    ].each do |k, options|
      describe "when exporting #{k}" do
        before(:each) do
          send(k).public_send(options[:export_method])
          @exported_class = options[:export_class]
        end
        it 'export scope should find five items' do
          scope = send(k).project_scope
          scope = scope.joins(options[:joins]) if options[:joins]
          expect(scope.count).to eq 5
        end
        it 'creates one CSV file' do
          expect(File.exist?(csv_file_path(send(k), @exported_class))).to be true
        end
        it "adds five rows to the #{options[:export_class].name} CSV file" do
          csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
          expect(csv.count).to eq 5
        end
        it "name from CSV matches name from #{options[:export_class].name}" do
          csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
          options[:fields].each do |field|
            expect(csv.first[field]).to eq @exported_class.first.send(field).to_s
            expect(csv.first[field]).to include('Name')
          end
        end
      end
    end
  end

  describe 'Project and organization confidential items' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
    end
    before(:each) do
      FactoryBot.reload
      projects.each { |p| p.update(confidential: true) }
      organizations.each { |p| p.update(confidential: true) }
      confidential.create_export_directory
      confidential.set_time_format
      confidential.setup_export
    end
    after(:each) do
      confidential.remove_export_files
      confidential.reset_time_format
      # The enrollments and project sequences seem to drift.
      # This ensures we'll have one to test
      FactoryBot.reload
    end
    [
      [
        :confidential,
        {
          export_method: :export_projects,
          export_class: HmisCsvTwentyTwentyTwo::Exporter::Project,
          fields: ['ProjectName', 'ProjectCommonName'],
        },
      ],
      [
        :confidential,
        {
          export_method: :export_organizations,
          export_class: HmisCsvTwentyTwentyTwo::Exporter::Organization,
          joins: :organization,
          fields: ['OrganizationName', 'OrganizationCommonName'],
        },
      ],
    ].each do |k, options|
      describe "when exporting #{k}" do
        before(:each) do
          send(k).public_send(options[:export_method])
          @exported_class = options[:export_class]
        end
        it 'export scope should find five items' do
          scope = send(k).project_scope
          scope = scope.joins(options[:joins]) if options[:joins]
          expect(scope.count).to eq 5
        end
        it 'creates one CSV file' do
          expect(File.exist?(csv_file_path(send(k), @exported_class))).to be true
        end
        it "adds five rows to the #{options[:export_class].name} CSV file" do
          csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
          expect(csv.count).to eq 5
        end
        it "name from CSV does not match name from #{options[:export_class].name}" do
          csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
          options[:fields].each do |field|
            # expect(csv.first[field]).to not_eq @exported_class.first.send(field).to_s
            expect(csv.first[field]).to include('Confidential')
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 confidential tests', include_shared: true
end
