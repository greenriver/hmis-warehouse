###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    setup_data

    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
      period_type: 3,
      directive: 3,
      hash_status: 4,
      user_id: @user.id,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)

    @exits.first.update(DateUpdated: DateTime.yesterday + 1.hours)
    @extra_exit = create(
      :hud_exit,
      data_source_id: @data_source.id,
      ExitDate: Date.yesterday,
      EnrollmentID: @enrollments.first.EnrollmentID,
      PersonalID: @enrollments.first.PersonalID,
      DateUpdated: DateTime.yesterday + 2.hours,
    )
    @exporter_2 = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter_2.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    @exporter_2.remove_export_files
    cleanup_test_environment
  end

  describe 'when exporting exits and there is more than one exit for an enrollment' do
    it 'adds only one row to the CSV file' do
      csv = CSV.read(csv_file_path(@exit_class, exporter: @exporter_2), headers: true)
      expect(csv.count).to eq 1
    end
    it 'DateUpdated from CSV file match the later exit record' do
      csv = CSV.read(csv_file_path(@exit_class, exporter: @exporter_2), headers: true)
      @exporter.set_time_format
      expect(csv.first['DateUpdated']).to eq @extra_exit.DateUpdated.to_s
      @exporter.reset_time_format
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

    it 'Does not limit the length of FirstName to 50 characters and differs from the source' do
      expect(@exporter.client_scope.first.FirstName.length).to be > 50
      csv = CSV.read(csv_file_path(@client_class), headers: true)
      expect(csv.first['FirstName'].length).to eq(64)
      expect(csv.first['FirstName']).to_not eq(@exporter.client_scope.first.FirstName)
    end

    it 'Does not limit the length of LastName to 50 characters and differs from the source' do
      expect(@exporter.client_scope.first.LastName.length).to be > 50
      csv = CSV.read(csv_file_path(@client_class), headers: true)
      expect(csv.first['LastName'].length).to eq(64)
      expect(csv.first['LastName']).to_not eq(@exporter.client_scope.first.LastName)
    end

    it 'MiddleName is hashed' do
      expect(@exporter.client_scope.first.MiddleName.length).to eq(1)
      csv = CSV.read(csv_file_path(@client_class), headers: true)
      expect(csv.first['MiddleName'].length).to eq(64)
      expect(csv.first['MiddleName']).to_not eq(@exporter.client_scope.first.MiddleName)
    end

    it 'Does not limit the length of SSN to 9 characters and differs from the source' do
      expect(@exporter.client_scope.first.SSN.length).to eq 9
      csv = CSV.read(csv_file_path(@client_class), headers: true)
      expect(csv.first['SSN'].length).to eq(68)
      expect(csv.first['SSN']).to_not eq(@exporter.client_scope.first.SSN)
      # Prepends last 4 of SSN per spec
      expect(@exporter.client_scope.first.SSN.last(4)).to eq(csv.first['SSN'].first(4))
    end
  end
end
