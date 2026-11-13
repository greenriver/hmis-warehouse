###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ImportLog, type: :model do
  let(:import_log) { described_class.create!(data_source: create(:grda_warehouse_data_source)) }

  describe '#files' do
    it 'round-trips an Array value' do
      import_log.update!(files: [['HmisCsvTwentyTwentyFour::Loader::Enrollment', 'Enrollment.csv']])

      expect(import_log.reload.files).to eq([['HmisCsvTwentyTwentyFour::Loader::Enrollment', 'Enrollment.csv']])
    end

    it 'rejects a non-Array value' do
      expect { import_log.update!(files: 'not an array') }.to raise_error(ActiveRecord::SerializationTypeMismatch)
    end
  end

  describe '#import_errors' do
    it 'round-trips an Array value' do
      import_log.update!(import_errors: [{ 'message' => 'boom' }])

      expect(import_log.reload.import_errors).to eq([{ 'message' => 'boom' }])
    end

    it 'rejects a non-Array value' do
      expect { import_log.update!(import_errors: 'not an array') }.to raise_error(ActiveRecord::SerializationTypeMismatch)
    end
  end

  describe '#summary' do
    it 'round-trips the real nested counts Hash shape used by the importer drivers' do
      import_log.update!(summary: { 'Enrollment.csv' => { 'total_lines' => 10, 'total_errors' => 0 } })

      expect(import_log.reload.summary).to eq({ 'Enrollment.csv' => { 'total_lines' => 10, 'total_errors' => 0 } })
    end

    it 'rejects a non-Hash value' do
      expect { import_log.update!(summary: 'not a hash') }.to raise_error(ActiveRecord::SerializationTypeMismatch)
    end
  end
end
