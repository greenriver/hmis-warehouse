require 'rails_helper'
require_relative './project_setup'
require_relative './enrollment_setup'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  include_context '2022 project setup'
  include_context '2022 enrollment setup'

  describe 'without overrides' do
    let(:exporter) do
      HmisCsvTwentyTwentyTwo::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: projects.map(&:id),
        coc_codes: projects.first.project_cocs.first.CoCCode,
        period_type: 3,
        directive: 3,
        user_id: user.id,
      )
    end

    before(:each) do
      exporter.create_export_directory
      exporter.set_time_format
      exporter.setup_export
      exporter.export_project_cocs
      exporter.export_enrollment_cocs
    end

    after(:each) do
      exporter.remove_export_files
      exporter.reset_time_format
      FactoryBot.reload
    end

    it 'filters ProjectCoC.csv' do
      csv = CSV.read(File.join(exporter.file_path, 'ProjectCoC.csv'), headers: true)
      expect(csv.count).to eq 1
    end

    it 'filters EnrollmentCoC.csv' do
      csv = CSV.read(File.join(exporter.file_path, 'EnrollmentCoC.csv'), headers: true)
      expect(csv.count).to eq 0
    end
  end

  describe 'with a ProjectCoC override' do
    let!(:override_project) { create :hud_project, hud_coc_code: projects.first.project_cocs.first.CoCCode, data_source_id: data_source.id }
    let!(:override_project_coc) { create :hud_project_coc, hud_coc_code: projects.first.project_cocs.first.CoCCode, data_source_id: data_source.id }

    let(:override_exporter) do
      HmisCsvTwentyTwentyTwo::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: projects.map(&:id) + [override_project.id],
        coc_codes: projects.first.project_cocs.first.CoCCode,
        period_type: 3,
        directive: 3,
        user_id: user.id,
      )
    end

    before(:each) do
      override_exporter.create_export_directory
      override_exporter.set_time_format
      override_exporter.setup_export
      override_exporter.export_project_cocs
      override_exporter.export_enrollment_cocs
    end

    after(:each) do
      override_exporter.remove_export_files
      override_exporter.reset_time_format
      FactoryBot.reload
    end

    it 'includes the ProjectCoC with the override' do
      csv = CSV.read(File.join(override_exporter.file_path, 'ProjectCoC.csv'), headers: true)
      expect(csv.count).to eq 2
    end
  end
end
