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

    # Set up non-confidential projects and organizations
    ExportHelper2024.organizations.each.with_index do |org, i|
      org.update(
        OrganizationID: (i + 1).to_s,
        OrganizationName: "Organization Name #{i + 1}",
        OrganizationCommonName: "Organization Common Name #{i + 1}",
      )
    end
    ExportHelper2024.projects.each.with_index do |proj, i|
      proj.update(
        ProjectName: "Project Name #{i + 1}",
        ProjectCommonName: "Project Common Name #{i + 1}",
        OrganizationID: (i + 1).to_s,
        ProjectType: 13,
      )
    end

    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: ExportHelper2024.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2024.user.id,
    )
    ExportHelper2024.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    ExportHelper2024.cleanup
  end

  [
    [
      :non_confidential,
      {
        export_class: HmisCsvTwentyTwentyFour::Exporter::Project,
        fields: ['ProjectName', 'ProjectCommonName'],
      },
    ],
    [
      :non_confidential,
      {
        export_class: HmisCsvTwentyTwentyFour::Exporter::Organization,
        joins: :organization,
        fields: ['OrganizationName', 'OrganizationCommonName'],
      },
    ],
  ].each do |k, options|
    describe "when exporting #{k}" do
      it 'export scope should find five items' do
        scope = @exporter.project_scope
        scope = scope.joins(options[:joins]) if options[:joins]
        expect(scope.count).to eq 5
      end
      it 'creates one CSV file' do
        expect(File.exist?(ExportHelper2024.csv_file_path(options[:export_class]))).to be true
      end
      it "adds five rows to the #{options[:export_class].name} CSV file" do
        csv = CSV.read(ExportHelper2024.csv_file_path(options[:export_class]), headers: true)
        expect(csv.count).to eq 5
      end
      it "name from CSV matches name from #{options[:export_class].name}" do
        csv = CSV.read(ExportHelper2024.csv_file_path(options[:export_class]), headers: true)
        options[:fields].each do |field|
          expect(csv.first[field]).to eq options[:export_class].hmis_class.first[field].to_s
          expect(csv.first[field]).to include('Name')
        end
      end
    end
  end
end

describe 'Project and organization confidential items' do
  before(:all) do
    cleanup_test_environment
    ExportHelper2024.setup_data

    # Set up confidential projects and organizations
    ExportHelper2024.organizations.map { |p| p.update(confidential: true) }
    ExportHelper2024.projects.map { |p| p.update(confidential: true) }

    @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: ExportHelper2024.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2024.user.id,
      confidential: true,
    )
    ExportHelper2024.instance_variable_set(:@exporter, @exporter)
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    ExportHelper2024.cleanup
  end

  [
    [
      :confidential,
      {
        export_class: HmisCsvTwentyTwentyFour::Exporter::Project,
        fields: ['ProjectName', 'ProjectCommonName'],
      },
    ],
    [
      :confidential,
      {
        export_class: HmisCsvTwentyTwentyFour::Exporter::Organization,
        joins: :organization,
        fields: ['OrganizationName', 'OrganizationCommonName'],
      },
    ],
  ].each do |k, options|
    describe "when exporting #{k}" do
      it 'export scope should find five items' do
        scope = @exporter.project_scope
        scope = scope.joins(options[:joins]) if options[:joins]
        expect(scope.count).to eq 5
      end
      it 'creates one CSV file' do
        expect(File.exist?(ExportHelper2024.csv_file_path(options[:export_class]))).to be true
      end
      it "adds five rows to the #{options[:export_class].name} CSV file" do
        csv = CSV.read(ExportHelper2024.csv_file_path(options[:export_class]), headers: true)
        expect(csv.count).to eq 5
      end
      it "name from CSV does not match name from #{options[:export_class].name}" do
        csv = CSV.read(ExportHelper2024.csv_file_path(options[:export_class]), headers: true)
        options[:fields].each do |field|
          expect(csv.first[field]).to include('Confidential')
        end
      end
    end
  end
end
