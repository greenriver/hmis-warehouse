###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'
require_relative './multi_enrollment_tests'

def project_test_type
  'enrollment date-based'
end

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  # Setup such that there are more than 3 of each item, but three fall within the date range
  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data

    @coc_code = 'XX-500'

    # Move 2 enrollments out of the range
    en_1 = ExportHelper2026.enrollments.min_by(&:id)
    en_1.update(EnrollmentCoC: nil)
    en_2 = ExportHelper2026.enrollments.max_by(&:id)
    en_2.update(EnrollmentCoC: 'XX-501')

    # Move two unrelated project CoCs out of the range
    p_cocs = ExportHelper2026.project_cocs.reject { |pc| pc.ProjectID.in?([en_1.ProjectID, en_1.ProjectID]) }.first(2)
    p_cocs.first.update!(CoCCode: nil)
    p_cocs.last.update!(CoCCode: 'XX-501')

    # Ensure we have a project that operates in 2 CoCs with enrollments in each
    @multi_coc_project = create :hud_project, data_source_id: ExportHelper2026.data_source.id
    create_list :hud_project_coc, 2, data_source_id: ExportHelper2026.data_source.id, CoCCode: 'XX-501', ProjectID: @multi_coc_project.ProjectID
    create_list :hud_enrollment, 3, data_source_id: ExportHelper2026.data_source.id, EntryDate: 2.weeks.ago, PreferredLanguageDifferent: 'a' * 10, EnrollmentCoC: 'XX-555', ProjectID: @multi_coc_project.ProjectID
    @multi_coc_project.project_cocs.first.update!(CoCCode: 'XX-500')
    @multi_coc_project.enrollments.first.update!(EnrollmentCoC: 'XX-500')
    @multi_coc_project.enrollments.last.update!(EnrollmentCoC: 'XX-501')

    # Ensure we have a project that operates in one CoC that isn't being included that has an enrollment missing EnrollmentCoC and bad
    @project_with_bad_enrollment_coc = create :hud_project, data_source_id: ExportHelper2026.data_source.id
    create :hud_project_coc, data_source_id: ExportHelper2026.data_source.id, CoCCode: 'XX-501', ProjectID: @project_with_bad_enrollment_coc.ProjectID
    create_list :hud_enrollment, 2, data_source_id: ExportHelper2026.data_source.id, EntryDate: 2.weeks.ago, PreferredLanguageDifferent: 'a' * 10, EnrollmentCoC: nil, ProjectID: @project_with_bad_enrollment_coc.ProjectID
    @project_with_bad_enrollment_coc.enrollments.first.update(EnrollmentCoC: 'BADCOC')

    # Ensure the new enrollments have clients
    create_list(
      :hud_client,
      4,
      data_source_id: ExportHelper2026.data_source.id,
      FirstName: 'abcde' * 12,
      LastName: 'xyz' * 50,
      MiddleName: 'M',
      SSN: Faker::Number.number(digits: 9),
    )

    @involved_project_ids = ExportHelper2026.projects.map(&:id) + [@multi_coc_project.id, @project_with_bad_enrollment_coc.id]
    @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 3.week.ago.to_date,
      end_date: 1.weeks.ago.to_date,
      projects: @involved_project_ids,
      coc_codes: [@coc_code], # Limit to one coc
      options: { 'coc_codes' => [@coc_code] }, # fake the filter setup
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2026.user.id,
    )
    ExportHelper2026.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    ExportHelper2026.cleanup
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
    it 'enrollment scope should find enrollments in the chosen CoC and where they are at projects operating in the CoC but the EnrollmentCoC is invalid' do
      expect(@exporter.enrollment_scope.count).to eq 4
      expect(@exporter.enrollment_scope.pluck(:EnrollmentCoC)).to eq(['XX-500', 'XX-555', nil])
    end
    it 'creates one CSV file' do
      expect(File.exist?(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class))).to be true
    end
    it 'adds expected rows to the enrollment CSV file' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class), headers: true)
      expect(csv.count).to eq 4
    end
    it 'EnrollmentIDs from CSV file match the ids of the enrollments in the CoC, are invalid, or are blank' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class), headers: true)
      csv_ids = csv.map { |m| m['EnrollmentID'] }.sort
      source_ids = involved_enrollments.select do |en|
        (en.EnrollmentCoC == @coc_code || en.EnrollmentCoC.blank? || ! HudUtility2026.valid_coc?(en.EnrollmentCoC)) && en.project.project_cocs.pluck(:CoCCode).include?(@coc_code)
      end.map(&:id).sort.map(&:to_s)
      expect(csv_ids).to eq source_ids
    end

    it 'project scope should find expected records' do
      expect(@exporter.project_scope.joins(:project_cocs).distinct.count).to eq 4
    end

    it 'adds expected rows to the project CSV file' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.project_class), headers: true)
      expect(csv.count).to eq 4
    end

    it 'creates one CSV file' do
      expect(File.exist?(ExportHelper2026.csv_file_path(ExportHelper2026.project_coc_class))).to be true
    end

    it 'adds expected rows to the project_coc CSV file' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.project_coc_class), headers: true)
      expect(csv.count).to eq 4
    end

    it 'ProjectCoC from CSV file match the ids of the project CoCs in the CoC' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.project_coc_class), headers: true)
      csv_ids = csv.map { |m| m['ProjectCoCID'] }.sort
      source_ids = involved_project_cocs.select { |en| en.CoCCode == @coc_code }.map(&:id).sort.map(&:to_s)
      expect(csv_ids).to eq source_ids
    end
  end
end
