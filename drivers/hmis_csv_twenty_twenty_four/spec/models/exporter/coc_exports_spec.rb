###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'
require_relative './multi_enrollment_tests'

def project_test_type
  'enrollment date-based'
end

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  # Setup such that there are more than 3 of each item, but three fall within the date range
  before(:all) do
    cleanup_test_environment
    setup_data

    @coc_code = 'XX-500'

    # Move 2 enrollments out of the range
    en_1 = @enrollments.min_by(&:id)
    en_1.update(EnrollmentCoC: nil)
    en_2 = @enrollments.max_by(&:id)
    en_2.update(EnrollmentCoC: 'XX-501')

    # Move two unrelated project CoCs out of the range
    p_cocs = @project_cocs.reject { |pc| pc.ProjectID.in?([en_1.ProjectID, en_1.ProjectID]) }.first(2)
    p_cocs.first.update(CoCCode: nil)
    p_cocs.last.update(CoCCode: 'XX-501')

    @involved_project_ids = @projects.map(&:id)
    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 3.week.ago.to_date,
      end_date: 1.weeks.ago.to_date,
      projects: @involved_project_ids,
      coc_codes: [@coc_code], # Limit to one coc
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    cleanup_test_environment
  end

  def involved_projects
    GrdaWarehouse::Hud::Project.where(id: @involved_project_ids)
  end

  def involved_enrollments
    GrdaWarehouse::Hud::Enrollment.order(id: :asc).where(ProjectID: involved_projects.select(:ProjectID))
  end

  def involved_project_cocs
    GrdaWarehouse::Hud::ProjectCoc.order(id: :asc).where(ProjectID: involved_projects.select(:ProjectID), CoCCode: @coc_code)
  end

  describe 'Exporting for one CoC' do
    it 'enrollment scope should find two enrollments' do
      expect(@exporter.enrollment_scope.count).to eq 2
    end
    it 'creates one CSV file' do
      expect(File.exist?(csv_file_path(@enrollment_class))).to be true
    end
    it 'adds two rows to the enrollment CSV file' do
      csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
      expect(csv.count).to eq 2
    end
    it 'EnrollmentIDs from CSV file match the ids of the two enrollments in the CoC or are blank' do
      csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
      csv_ids = csv.map { |m| m['EnrollmentID'] }.sort
      source_ids = involved_enrollments.select { |en| (en.EnrollmentCoC == @coc_code || en.EnrollmentCoC.blank?) && en.project.project_cocs.pluck(:CoCCode).include?(@coc_code) }.map(&:id).sort.map(&:to_s)
      expect(csv_ids).to eq source_ids
    end

    it 'project_coc scope should find three enrollments' do
      expect(@exporter.project_scope.joins(:project_cocs).count).to eq 3
    end
    it 'creates one CSV file' do
      expect(File.exist?(csv_file_path(@project_coc_class))).to be true
    end
    it 'adds three rows to the project_coc CSV file' do
      csv = CSV.read(csv_file_path(@project_coc_class), headers: true)
      expect(csv.count).to eq 3
    end
    it 'ProjectCoC from CSV file match the ids of the three project CoCs in the CoC' do
      csv = CSV.read(csv_file_path(@project_coc_class), headers: true)
      csv_ids = csv.map { |m| m['ProjectCoCID'] }.sort
      source_ids = involved_project_cocs.select { |en| en.CoCCode == @coc_code }.map(&:id).sort.map(&:to_s)
      expect(csv_ids).to eq source_ids
    end
  end
end
