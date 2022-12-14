###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  def delete_records
    @enrollments.first.update(DateDeleted: Date.current)
  end

  before(:all) do
    cleanup_test_environment
    setup_data
    delete_records
  end

  after(:all) do
    cleanup_test_environment
  end

  describe 'When include deleted is not set:' do
    before(:all) do
      @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: @projects.map(&:id),
        period_type: 3,
        directive: 3,
        user_id: @user.id,
      )
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      @exporter.remove_export_files
    end

    it 'Only exports undeleted enrollments' do
      csv = CSV.read(File.join(@exporter.file_path, 'Enrollment.csv'), headers: true)
      expect(csv.count).to eq 4
    end
  end

  describe 'When include deleted is set:' do
    before(:all) do
      @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
        include_deleted: true,
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: @projects.map(&:id),
        period_type: 3,
        directive: 3,
        user_id: @user.id,
      )
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      @exporter.remove_export_files
    end

    it 'Exports deleted enrollments' do
      csv = CSV.read(File.join(@exporter.file_path, 'Enrollment.csv'), headers: true)
      expect(csv.count).to eq 5
    end
  end
end
