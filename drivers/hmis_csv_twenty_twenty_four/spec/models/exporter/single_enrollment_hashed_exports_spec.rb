###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2024'

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2024.setup_data

    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [ExportHelper2024.projects.first.id],
      period_type: 3,
      directive: 3,
      hash_status: 4,
      user_id: ExportHelper2024.user.id,
    )
    ExportHelper2024.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)

    ExportHelper2024.exits.first.update(DateUpdated: DateTime.yesterday + 1.hours)
    @extra_exit = FactoryBot.create(
      :hud_exit,
      data_source_id: ExportHelper2024.data_source.id,
      ExitDate: Date.yesterday,
      EnrollmentID: ExportHelper2024.enrollments.first.EnrollmentID,
      PersonalID: ExportHelper2024.enrollments.first.PersonalID,
      DateUpdated: DateTime.yesterday + 2.hours,
    )
    @exporter_2 = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [ExportHelper2024.projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2024.user.id,
    )
    @exporter_2.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files if @exporter.respond_to?(:remove_export_files)
    @exporter_2.remove_export_files if @exporter_2.respond_to?(:remove_export_files)
    @extra_exit.destroy if @extra_exit.present?
    ExportHelper2024.cleanup
  end

  describe 'when exporting exits and there is more than one exit for an enrollment' do
    it 'adds only one row to the CSV file' do
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.exit_class, exporter: @exporter_2), headers: true)
      expect(csv.count).to eq 1
    end
    it 'DateUpdated from CSV file match the later exit record' do
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.exit_class, exporter: @exporter_2), headers: true)
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
      expect(File.exist?(ExportHelper2024.csv_file_path(ExportHelper2024.client_class))).to be true
    end

    it 'adds one row to the CSV file' do
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.client_class), headers: true)
      expect(csv.count).to eq 1
    end

    it 'Does not limit the length of FirstName to 50 characters and differs from the source' do
      expect(@exporter.client_scope.first.FirstName.length).to be > 50
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.client_class), headers: true)
      expect(csv.first['FirstName'].length).to eq(64)
      expect(csv.first['FirstName']).to_not eq(@exporter.client_scope.first.FirstName)
    end

    it 'Does not limit the length of LastName to 50 characters and differs from the source' do
      expect(@exporter.client_scope.first.LastName.length).to be > 50
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.client_class), headers: true)
      expect(csv.first['LastName'].length).to eq(64)
      expect(csv.first['LastName']).to_not eq(@exporter.client_scope.first.LastName)
    end

    it 'MiddleName is hashed' do
      expect(@exporter.client_scope.first.MiddleName.length).to eq(1)
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.client_class), headers: true)
      expect(csv.first['MiddleName'].length).to eq(64)
      expect(csv.first['MiddleName']).to_not eq(@exporter.client_scope.first.MiddleName)
    end

    it 'Does not limit the length of SSN to 9 characters and differs from the source' do
      expect(@exporter.client_scope.first.SSN.length).to eq 9
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.client_class), headers: true)
      expect(csv.first['SSN'].length).to eq(68)
      expect(csv.first['SSN']).to_not eq(@exporter.client_scope.first.SSN)
      # Prepends last 4 of SSN per spec
      expect(@exporter.client_scope.first.SSN.last(4)).to eq(csv.first['SSN'].first(4))
    end
  end
end
