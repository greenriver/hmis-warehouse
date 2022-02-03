###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 single-enrollment tests', shared_context: :metadata do
  describe 'When exporting enrollment related item' do
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
    describe 'when exporting enrollments' do
      before(:each) do
        exporter.export_enrollments
        @enrollment_class = HmisCsvTwentyTwentyTwo::Exporter::Enrollment
      end
      it 'enrollment scope should find one enrollment' do
        expect(exporter.enrollment_scope.count).to eq 1
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(@enrollment_class))).to be true
      end
      it 'adds one row to the enrollment CSV file' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.count).to eq 1
      end
      it 'EnrollmentID from CSV file match the id of first enrollment' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.first['EnrollmentID']).to eq enrollments.first.id.to_s
      end

      it 'PersonalID from CSV file is not blank' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.first['PersonalID']).to_not be_empty
      end
    end
    describe 'when exporting clients' do
      before(:each) do
        exporter.export_clients
        @client_class = HmisCsvTwentyTwentyTwo::Exporter::Client
      end
      it 'client scope should find one client' do
        expect(exporter.client_scope.count).to eq 1
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(@client_class))).to be true
      end
      it 'adds one row to the CSV file' do
        csv = CSV.read(csv_file_path(@client_class), headers: true)
        expect(csv.count).to eq 1
      end
      it 'PersonalID from CSV file match the id of first client' do
        csv = CSV.read(csv_file_path(@client_class), headers: true)
        expect(csv.first['PersonalID']).to eq clients.first.destination_client.id.to_s
      end
    end
    EnrollmentRelatedHmisTwentyTwentyTests::TESTS.each do |item|
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
        if item[:klass].column_names.include?('EnrollmentID')
          it 'EnrollmentID from CSV file match the id of first enrollment' do
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            expect(csv.first['EnrollmentID']).to eq enrollments.first.id.to_s
          end
        end
        if item[:klass].column_names.include?('PersonalID')
          it 'PersonalID from CSV file match the id of first client' do
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            expect(csv.first['PersonalID']).to_not be_empty
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 single-enrollment tests', include_shared: true
end
