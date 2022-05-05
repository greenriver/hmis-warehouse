###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context '2022 multi-enrollment tests', shared_context: :metadata do
  def involved_projects
    GrdaWarehouse::Hud::Project.where(id: involved_project_ids)
  end

  def involved_enrollments
    GrdaWarehouse::Hud::Enrollment.where(ProjectID: involved_projects.select(:ProjectID))
  end

  def involved_clients
    GrdaWarehouse::Hud::Client.joins(:enrollments).where(GrdaWarehouse::Hud::Enrollment.arel_table[:id].in(involved_enrollments.pluck(:id)))
  end

  describe "When exporting enrollment related items for #{project_test_type}" do
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
        # puts 3.weeks.ago.to_date
        # puts 1.weeks.ago.to_date
        # puts projects.map(&:ProjectID).inspect
        # puts enrollments.map{|m| [m.ProjectID, m.EnrollmentID, m.EntryDate]}.inspect
        # puts exits.map{|m| [ m.EnrollmentID, m.ExitDate]}.inspect
        exporter.export_enrollments
        @enrollment_class = HmisCsvTwentyTwentyTwo::Exporter::Enrollment
      end
      it 'enrollment scope should find three enrollments' do
        expect(exporter.enrollment_scope.count).to eq 3
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
      before(:each) do
        exporter.export_clients
        @client_class = HmisCsvTwentyTwentyTwo::Exporter::Client
      end
      it 'client scope should find three clients' do
        expect(exporter.client_scope.count).to eq 3
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
    EnrollmentRelatedHmisTwentyTwentyTests::TESTS.each do |item|
      describe "when exporting #{item[:list]}" do
        before(:each) do
          exporter.public_send(item[:export_method])
        end
        it "creates one #{exporter.file_name_for(item[:klass])} CSV file" do
          expect(File.exist?(csv_file_path(item[:klass]))).to be true
        end
        it "adds three rows to the #{exporter.file_name_for(item[:klass])} CSV file" do
          csv = CSV.read(csv_file_path(item[:klass]), headers: true)
          expect(csv.count).to eq 3
        end
        it 'hud keys in CSV should match ids of first three items in list' do
          csv = CSV.read(csv_file_path(item[:klass]), headers: true)
          current_hud_key = item[:klass].new.clean_headers([item[:klass].hud_key]).first.to_s
          csv_ids = csv.map { |m| m[current_hud_key] }.sort
          # source_ids = send(item[:list]).first(3).map(&:id).map(&:to_s).sort

          involved_enrollment_project_entry_ids = involved_enrollments.pluck(:EnrollmentID)
          source_ids = send(item[:list]).select do |m|
            involved_enrollment_project_entry_ids.include? m.EnrollmentID
          end.map(&:id).map(&:to_s).sort.first(3)
          expect(csv_ids).to eq source_ids
        end
        if item[:klass].hmis_class.column_names.include?('EnrollmentID')
          it 'EnrollmentIDs from CSV file match the ids of first three enrollments' do
            # binding.pry if item[:list] == :exits
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
            csv_ids = csv.map { |m| m['EnrollmentID'] }.sort
            source_ids = involved_enrollments.map(&:id).map(&:to_s).sort.first(3)
            expect(csv_ids).to eq source_ids
          end
        end
        if item[:klass].hmis_class.column_names.include?('PersonalID')
          it 'PersonalID from CSV should not be blank' do
            # binding.pry if item[:list] == :exits
            csv = CSV.read(csv_file_path(item[:klass]), headers: true)
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
