###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'
require_relative './single_enrollment_tests'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data

    @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: ExportHelper2026.projects.first.id,
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2026.user.id,
    )
    ExportHelper2026.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)

    ExportHelper2026.exits.first.update(DateUpdated: DateTime.yesterday + 1.hours)
    @extra_exit = FactoryBot.create(
      :hud_exit,
      data_source_id: ExportHelper2026.data_source.id,
      ExitDate: Date.yesterday,
      EnrollmentID: ExportHelper2026.enrollments.first.EnrollmentID,
      PersonalID: ExportHelper2026.enrollments.first.PersonalID,
      DateUpdated: DateTime.yesterday + 2.hours,
    )
    @exporter_2 = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [ExportHelper2026.projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2026.user.id,
    )
    @exporter_2.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    ExportHelper2026.cleanup
    @exporter.remove_export_files
    @exporter_2.remove_export_files
  end

  describe 'when exporting exits and there is more than one exit for an enrollment' do
    it 'adds only one row to the CSV file' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.exit_class, exporter: @exporter_2), headers: true)
      expect(csv.count).to eq 1
    end
    it 'DateUpdated from CSV file match the later exit record' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.exit_class, exporter: @exporter_2), headers: true)
      @exporter.set_time_format
      expect(csv.first['DateUpdated']).to eq @extra_exit.DateUpdated.to_s
      @exporter.reset_time_format
    end
  end

  include_context '2026 single-enrollment tests'
end
