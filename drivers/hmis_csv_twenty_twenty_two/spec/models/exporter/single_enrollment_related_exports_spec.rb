###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'
require_relative './single_enrollment_tests'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    setup_data

    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
      period_type: 3,
      directive: 3,
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
    @exporter_2 = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
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

  include_context '2022 single-enrollment tests'
end
