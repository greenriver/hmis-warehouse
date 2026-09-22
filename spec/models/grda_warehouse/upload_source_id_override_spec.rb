###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Upload, type: :model do
  # This decides whether HmisCsvImporter::Loader::Loader#export_file_valid? skips
  # its own SourceID comparison, so each arm is covered directly.
  describe '#source_id_overridden?' do
    let(:upload) { create(:grda_warehouse_upload) }

    def acknowledge(expected:, observed:, check_error: nil)
      upload.update!(
        export_source_check: {
          'typed_short_name' => 'HV',
          'data_source_source_id' => expected,
          'file_source_id' => observed,
          'check_error' => check_error,
          'acknowledged_at' => Time.current,
          'acknowledged_by_user_id' => upload.user_id,
        },
      )
      upload
    end

    it 'is false when nothing was acknowledged' do
      expect(upload.source_id_overridden?).to be false
    end

    it 'is false when the record exists but carries no acknowledgment' do
      upload.update!(export_source_check: { 'file_source_id' => 'MA-999' })

      expect(upload.source_id_overridden?).to be false
    end

    # A blank configured source_id means the Loader never compares, so nothing
    # was overridden even though the user confirmed.
    it 'is false when no source_id was configured on the data source' do
      expect(acknowledge(expected: '', observed: 'MA-999').source_id_overridden?).to be false
    end

    it 'is false when the values match' do
      expect(acknowledge(expected: 'MA-500', observed: 'MA-500').source_id_overridden?).to be false
    end

    it 'is false when the values differ only by case' do
      expect(acknowledge(expected: 'MA-500', observed: 'ma-500').source_id_overridden?).to be false
    end

    it 'is true when the values differ' do
      expect(acknowledge(expected: 'MA-500', observed: 'MA-999').source_id_overridden?).to be true
    end

    it 'is true when the file carried no SourceID' do
      expect(acknowledge(expected: 'MA-500', observed: '').source_id_overridden?).to be true
    end

    # The archive could not be opened before queuing, but the Loader expands it
    # and can run the comparison itself, so confirming must not waive it.
    it 'is false when no SourceID was read because the archive was unreadable' do
      upload = acknowledge(expected: 'MA-500', observed: nil, check_error: 'unverifiable')

      expect(upload.source_id_overridden?).to be false
    end
  end
end
