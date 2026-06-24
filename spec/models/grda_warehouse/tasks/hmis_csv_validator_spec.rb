###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::HmisCsvValidator do
  let(:tmp_path) { Dir.mktmpdir }
  let(:nbsp) { "\u00A0" }

  after { FileUtils.rm_rf(tmp_path) }

  # Write a minimal CurrentLivingSituation.csv to tmp_path with the given LocationDetails value
  def write_cls_csv(location_details:)
    headers = ['CurrentLivingSitID', 'EnrollmentID', 'PersonalID', 'InformationDate', 'CurrentLivingSituation', 'LocationDetails', 'ExportID', 'UserID']
    row = ['cls-1', 'enroll-1', 'personal-1', '2024-01-01', '116', location_details, 'export-1', 'user-1']
    CSV.open(File.join(tmp_path, 'CurrentLivingSituation.csv'), 'wb', write_headers: true, headers: headers) do |csv|
      csv << row
    end
  end

  describe 'LocationDetails length validation' do
    context 'with version 2026 (UTF-8)' do
      let(:validator) { described_class.new(tmp_path, version: '2026') }

      it 'accepts a 250-character field containing non-breaking spaces' do
        # 249 ASCII chars + 1 NBSP = 250 Unicode characters, valid
        value = ('A' * 249) + nbsp
        write_cls_csv(location_details: value)
        validator.run!

        over_length_errors = validator.errors&.dig('CurrentLivingSituation.csv', 'LocationDetails')
        expect(over_length_errors).to be_nil
      end

      it 'rejects a field exceeding 250 characters even with non-breaking spaces' do
        # 250 ASCII chars + 1 NBSP = 251 Unicode characters, invalid
        value = ('A' * 250) + nbsp
        write_cls_csv(location_details: value)
        validator.run!

        over_length_errors = validator.errors&.dig('CurrentLivingSituation.csv', 'LocationDetails')
        expect(over_length_errors).to include('Over-length' => a_hash_including(count: 1))
      end
    end
  end
end
