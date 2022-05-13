###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 multi-enrollment tests', shared_context: :metadata do
  def involved_projects
    GrdaWarehouse::Hud::Project.where(id: @involved_project_ids)
  end

  def involved_enrollments
    GrdaWarehouse::Hud::Enrollment.where(ProjectID: involved_projects.select(:ProjectID))
  end

  def involved_clients
    GrdaWarehouse::Hud::Client.joins(:enrollments).where(GrdaWarehouse::Hud::Enrollment.arel_table[:id].in(involved_enrollments.pluck(:id)))
  end

  describe "When exporting enrollment related items for #{project_test_type}" do
    describe 'when exporting enrollments' do
      it 'enrollment scope should find three enrollments' do
        expect(@exporter.enrollment_scope.count).to eq 3
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(@enrollment_class))).to be true
      end
      it 'adds three rows to the enrollment CSV file' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.count).to eq 3
      end
      it 'EnrollmentIDs from CSV file match the ids of first three enrollments' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        csv_ids = csv.map { |m| m['EnrollmentID'] }.sort
        source_ids = involved_enrollments.map(&:id).map(&:to_s).sort.first(3)
        expect(csv_ids).to eq source_ids
      end
      it 'PersonalID from CSV should not be blank' do
        csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
        expect(csv.first['PersonalID']).to_not be_empty
      end
    end
    describe 'when exporting clients' do
      it 'client scope should find three clients' do
        expect(@exporter.client_scope.count).to eq 3
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(@client_class))).to be true
      end
      it 'adds three row to the CSV file' do
        csv = CSV.read(csv_file_path(@client_class), headers: true)
        expect(csv.count).to eq 3
      end
      it 'PersonalIDs from CSV file match the ids of first three clients' do
        csv = CSV.read(csv_file_path(@client_class), headers: true)

        csv_ids = csv.map { |m| m['PersonalID'] }.sort
        source_ids = involved_clients.map(&:destination_client).map(&:id).map(&:to_s).sort.first(3)
        expect(csv_ids).to eq source_ids
      end
    end

    enrollment_related_items.each do |items, klass|
      describe "when exporting #{items}" do
        it "creates one #{klass.hud_csv_file_name} CSV file" do
          expect(File.exist?(csv_file_path(klass))).to be true
        end
        it "adds three rows to the #{klass.hud_csv_file_name} CSV file" do
          csv = CSV.read(csv_file_path(klass), headers: true)
          expect(csv.count).to eq 3
        end
        it 'hud keys in CSV should match ids of first three items in list' do
          csv = CSV.read(csv_file_path(klass), headers: true)
          hmis_class = klass.hmis_class
          csv_ids = csv.map { |m| m[hmis_class.hud_key.to_s] }.sort
          involved_enrollment_project_entry_ids = involved_enrollments.pluck(:EnrollmentID)
          source_ids = instance_variable_get("@#{items}").select do |m|
            involved_enrollment_project_entry_ids.include? m.EnrollmentID
          end.map(&:id).map(&:to_s).sort.first(3)
          expect(csv_ids).to eq source_ids
        end
        if klass.hmis_class.column_names.include?('EnrollmentID')
          it 'EnrollmentIDs from CSV file match the ids of first three enrollments' do
            # binding.pry if items == :exits
            csv = CSV.read(csv_file_path(klass), headers: true)
            csv_ids = csv.map { |m| m['EnrollmentID'] }.sort
            source_ids = involved_enrollments.map(&:id).map(&:to_s).sort.first(3)
            expect(csv_ids).to eq source_ids
          end
        end
        if klass.hmis_class.column_names.include?('PersonalID')
          it 'PersonalID from CSV should not be blank' do
            # binding.pry if items == :exits
            csv = CSV.read(csv_file_path(klass), headers: true)
            expect(csv.first['PersonalID']).to_not be_empty
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 multi-enrollment tests', include_shared: true
end
