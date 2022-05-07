###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 single-enrollment tests', shared_context: :metadata do
  describe 'when exporting enrollments' do
    it 'enrollment scope should find one enrollment' do
      expect(@exporter.enrollment_scope.count).to eq 1
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
      expect(csv.first['EnrollmentID']).to eq @enrollments.first.id.to_s
    end

    it 'PersonalID from CSV file is not blank' do
      csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
      expect(csv.first['PersonalID']).to_not be_empty
    end
  end
  describe 'when exporting clients' do
    it 'client scope should find one client' do
      expect(@exporter.client_scope.count).to eq 1
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
      expect(csv.first['PersonalID']).to eq @clients.first.destination_client.id.to_s
    end
  end
  enrollment_related_items.each do |items, klass|
    describe "when exporting #{items}" do
      it "creates one #{klass.hud_csv_file_name} CSV file" do
        expect(File.exist?(csv_file_path(klass))).to be true
      end
      it "adds one row to the #{klass.hud_csv_file_name} CSV file" do
        csv = CSV.read(csv_file_path(klass), headers: true)
        expect(csv.count).to eq 1
      end
      it 'hud key in CSV should match id of first item in list' do
        csv = CSV.read(csv_file_path(klass), headers: true)
        expect(csv.first[klass.hmis_class.hud_key.to_s]).to eq instance_variable_get("@#{items}").first.id.to_s
      end
      if klass.hmis_class.column_names.include?('EnrollmentID')
        it 'EnrollmentID from CSV file match the id of first enrollment' do
          csv = CSV.read(csv_file_path(klass), headers: true)
          expect(csv.first['EnrollmentID']).to eq @enrollments.first.id.to_s
        end
      end
      if klass.hmis_class.column_names.include?('PersonalID')
        it 'PersonalID from CSV file match the id of first client' do
          csv = CSV.read(csv_file_path(klass), headers: true)
          expect(csv.first['PersonalID']).to_not be_empty
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 single-enrollment tests', include_shared: true
end
