###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    setup_data
    @organizations.each.with_index do |org, i|
      org.update(
        OrganizationID: (i + 1).to_s,
        OrganizationName: "Organization Name #{i + 1}",
        OrganizationCommonName: "Organization Common Name #{i + 1}",
      )
    end
    @projects.each.with_index do |proj, i|
      proj.update(
        ProjectName: "Project Name #{i + 1}",
        ProjectCommonName: "Project Common Name #{i + 1}",
        OrganizationID: (i + 1).to_s,
        ProjectType: 1,
        act_as_project_type: 13,
        computed_project_type: 13,
      )
    end

    @project_class = HmisCsvTwentyTwentyTwo::Exporter::Project
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
    cleanup_test_environment
  end

  [
    [
      :non_confidential,
      {
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Project,
        fields: ['ProjectName', 'ProjectCommonName'],
      },
    ],
    [
      :non_confidential,
      {
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Organization,
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
        expect(File.exist?(csv_file_path(options[:export_class]))).to be true
      end
      it "adds five rows to the #{options[:export_class].name} CSV file" do
        csv = CSV.read(csv_file_path(options[:export_class]), headers: true)
        expect(csv.count).to eq 5
      end
      it "name from CSV matches name from #{options[:export_class].name}" do
        csv = CSV.read(csv_file_path(options[:export_class]), headers: true)
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
    setup_data
    @organizations.map { |p| p.update(confidential: true) }
    @projects.map { |p| p.update(confidential: true) }

    @project_class = HmisCsvTwentyTwentyTwo::Exporter::Project
    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: @projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: @user.id,
      confidential: true,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    cleanup_test_environment
  end

  [
    [
      :confidential,
      {
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Project,
        fields: ['ProjectName', 'ProjectCommonName'],
      },
    ],
    [
      :confidential,
      {
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Organization,
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
        expect(File.exist?(csv_file_path(options[:export_class]))).to be true
      end
      it "adds five rows to the #{options[:export_class].name} CSV file" do
        csv = CSV.read(csv_file_path(options[:export_class]), headers: true)
        expect(csv.count).to eq 5
      end
      it "name from CSV does not match name from #{options[:export_class].name}" do
        csv = CSV.read(csv_file_path(options[:export_class]), headers: true)
        options[:fields].each do |field|
          # expect(csv.first[field]).to not_eq options[:export_class].hmis_class.first.instance_variable_get(field).to_s
          expect(csv.first[field]).to include('Confidential')
        end
      end
    end
  end
end
