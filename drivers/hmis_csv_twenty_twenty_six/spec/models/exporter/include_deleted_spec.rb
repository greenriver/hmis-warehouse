###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  def delete_records
    ExportHelper2026.enrollments.first.update(DateDeleted: Date.current)
  end

  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data
    delete_records
  end

  after(:all) do
    ExportHelper2026.cleanup
  end

  describe 'When include deleted is not set:' do
    before(:all) do
      @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: ExportHelper2026.projects.map(&:id),
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2026.user.id,
      )
      ExportHelper2026.instance_variable_set(:@exporter, @exporter)
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      @exporter.remove_export_files if @exporter.respond_to?(:remove_export_files)
    end

    it 'Only exports undeleted enrollments' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class), headers: true)
      expect(csv.count).to eq 4
    end
  end

  describe 'When include deleted is set:' do
    before(:all) do
      @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
        include_deleted: true,
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: ExportHelper2026.projects.map(&:id),
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2026.user.id,
      )
      ExportHelper2026.instance_variable_set(:@exporter, @exporter)
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      @exporter.remove_export_files if @exporter.respond_to?(:remove_export_files)
    end

    it 'Exports deleted enrollments' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class), headers: true)
      expect(csv.count).to eq 5
    end
  end
end
