###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative './confidential_setup'
require_relative './confidential_tests'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:destination_data_source) { create :grda_warehouse_data_source }
  let!(:user) { create :user }
  let!(:clients) do
    [].tap do |c|
      5.times do |i|
        c << create(
          :hud_client,
          data_source_id: data_source.id,
          PersonalID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:destination_clients) do
    clients.map do |client|
      attributes = client.attributes
      attributes['data_source_id'] = destination_data_source.id
      attributes['id'] = nil
      dest_client = GrdaWarehouse::Hud::Client.create(attributes)
      GrdaWarehouse::WarehouseClient.create(
        id_in_source: client.PersonalID,
        data_source_id: client.data_source_id,
        source_id: client.id,
        destination_id: dest_client.id,
      )
    end
  end

  let!(:organizations) do
    [].tap do |organization|
      5.times do |i|
        organization << create(
          :hud_organization,
          OrganizationID: (i + 1).to_s,
          OrganizationName: "Organization Name #{i + 1}",
          OrganizationCommonName: "Organization Common Name #{i + 1}",
          data_source_id: data_source.id,
        )
      end
    end
  end

  let!(:projects) do
    [].tap do |project|
      5.times do |i|
        project << create(
          :hud_project,
          ProjectID: (i + 1).to_s,
          ProjectName: "Project Name #{i + 1}",
          ProjectCommonName: "Project Common Name #{i + 1}",
          OrganizationID: (i + 1).to_s,
          data_source_id: data_source.id,
          ProjectType: 1,
          act_as_project_type: 13,
          computed_project_type: 13,
        )
      end
    end
  end
  let!(:project_cocs) do
    [].tap do |pc|
      5.times do |i|
        pc << create(
          :hud_project_coc,
          data_source_id: data_source.id,
          CoCCode: 'XX-500',
          ProjectID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:inventories) do
    [].tap do |inventory|
      5.times do |i|
        inventory << create(
          :hud_inventory,
          data_source_id: data_source.id,
          CoCCode: 'XX-501',
          ProjectID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:enrollments) do
    [].tap do |e|
      5.times do |i|
        e << create(
          :hud_enrollment,
          data_source_id: data_source.id,
          EntryDate: 2.weeks.ago,
          PersonalID: (i + 1).to_s,
          ProjectID: (i + 1).to_s,
          EnrollmentID: (i + 1).to_s,
        )
      end
    end
  end
  let!(:enrollment_cocs) do
    [].tap do |e|
      5.times do |i|
        e << create(
          :hud_enrollment_coc,
          data_source_id: data_source.id,
          InformationDate: 2.months.ago,
          CoCCode: 'XX-502',
          EnrollmentID: (i + 1).to_s,
          PersonalID: (i + 1).to_s,
          ProjectID: (i + 1).to_s,
        )
      end
    end
  end

  let(:non_confidential) do
    HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: user.id,
    )
  end

  let(:confidential) do
    HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: user.id,
      confidential: true,
    )
  end

  before(:all) do
    GrdaWarehouse::Utility.clear!
  end
  before(:each) do
    FactoryBot.reload
    non_confidential.create_export_directory
    non_confidential.set_time_format
    non_confidential.setup_export
  end
  after(:each) do
    non_confidential.remove_export_files
    non_confidential.reset_time_format
    # The enrollments and project sequences seem to drift.
    # This ensures we'll have one to test
    FactoryBot.reload
  end
  [
    [
      :non_confidential,
      {
        export_method: :export_projects,
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Project,
        fields: ['ProjectName', 'ProjectCommonName'],
      },
    ],
    [
      :non_confidential,
      {
        export_method: :export_organizations,
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Organization,
        joins: :organization,
        fields: ['OrganizationName', 'OrganizationCommonName'],
      },
    ],
  ].each do |k, options|
    describe "when exporting #{k}" do
      before(:each) do
        send(k).public_send(options[:export_method])
        @exported_class = options[:export_class]
      end
      it 'export scope should find five items' do
        scope = send(k).project_scope
        scope = scope.joins(options[:joins]) if options[:joins]
        expect(scope.count).to eq 5
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(send(k), @exported_class))).to be true
      end
      it "adds five rows to the #{options[:export_class].name} CSV file" do
        csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
        expect(csv.count).to eq 5
      end
      it "name from CSV matches name from #{options[:export_class].name}" do
        csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
        options[:fields].each do |field|
          expect(csv.first[field]).to eq @exported_class.first.send(field).to_s
          expect(csv.first[field]).to include('Name')
        end
      end
    end
  end
end

describe 'Project and organization confidential items' do
  before(:all) do
    GrdaWarehouse::Utility.clear!
  end
  before(:each) do
    FactoryBot.reload
    projects.each { |p| p.update(confidential: true) }
    organizations.each { |p| p.update(confidential: true) }
    confidential.create_export_directory
    confidential.set_time_format
    confidential.setup_export
  end
  after(:each) do
    confidential.remove_export_files
    confidential.reset_time_format
    # The enrollments and project sequences seem to drift.
    # This ensures we'll have one to test
    FactoryBot.reload
  end
  [
    [
      :confidential,
      {
        export_method: :export_projects,
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Project,
        fields: ['ProjectName', 'ProjectCommonName'],
      },
    ],
    [
      :confidential,
      {
        export_method: :export_organizations,
        export_class: HmisCsvTwentyTwentyTwo::Exporter::Organization,
        joins: :organization,
        fields: ['OrganizationName', 'OrganizationCommonName'],
      },
    ],
  ].each do |k, options|
    describe "when exporting #{k}" do
      before(:each) do
        send(k).public_send(options[:export_method])
        @exported_class = options[:export_class]
      end
      it 'export scope should find five items' do
        scope = send(k).project_scope
        scope = scope.joins(options[:joins]) if options[:joins]
        expect(scope.count).to eq 5
      end
      it 'creates one CSV file' do
        expect(File.exist?(csv_file_path(send(k), @exported_class))).to be true
      end
      it "adds five rows to the #{options[:export_class].name} CSV file" do
        csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
        expect(csv.count).to eq 5
      end
      it "name from CSV does not match name from #{options[:export_class].name}" do
        csv = CSV.read(csv_file_path(send(k), @exported_class), headers: true)
        options[:fields].each do |field|
          # expect(csv.first[field]).to not_eq @exported_class.first.send(field).to_s
          expect(csv.first[field]).to include('Confidential')
        end
      end
    end
  end
end
