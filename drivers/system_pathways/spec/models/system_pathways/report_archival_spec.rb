###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemPathways::Report, type: :model do
  before(:all) do
    connection = GrdaWarehouseBase.connection
    connection.add_column :simple_report_instances, :archival_metadata, :jsonb unless connection.column_exists?(:simple_report_instances, :archival_metadata)
  end

  let(:report) { described_class.create!(user_id: User.system_user.id) }
  let(:report_type) { described_class.name.gsub('::', '-').underscore }

  it 'includes ReportArchival' do
    expect(described_class.included_modules).to include(ReportArchival)
  end

  it 'is registered for archival' do
    expect(Rails.application.config.report_archival_types).to include(described_class.name)
  end

  describe '#archival_csv_config' do
    subject(:config) { report.archival_csv_config }

    it 'has an entry for each archived attachment' do
      expect(config.keys).to match_array([:clients_csv, :enrollments_csv])
    end

    it 'each entry declares an :association and :filename' do
      config.each do |key, entry|
        expect(entry).to include(:association, :filename), "missing keys for #{key}"
        expect(entry[:filename]).to be_a(Proc)
      end
    end

    it 'each attachment is declared via has_many_attached' do
      config.each_key do |attachment_name|
        expect(report).to respond_to(attachment_name)
        expect(report.public_send(attachment_name)).to be_an(ActiveStorage::Attached::Many)
      end
    end

    it 'each :association resolves on the report' do
      config.each_value do |entry|
        expect(report).to respond_to(entry[:association])
      end
    end

    it 'filenames include the report id and report type' do
      config.each_value do |entry|
        filename = report.instance_exec(&entry[:filename])
        expect(filename).to end_with("-#{report.id}.csv")
        expect(filename).to start_with("#{report_type}-")
      end
    end
  end
end
