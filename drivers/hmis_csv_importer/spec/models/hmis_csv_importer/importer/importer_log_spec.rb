###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::ImporterLog, type: :model do
  describe '#post_processing_time' do
    let(:log_completed_at) { Time.zone.local(2026, 1, 5, 9, 0) }
    let(:import_completed_at) { Time.zone.local(2026, 1, 5, 9, 30) }
    let(:importer_log) { described_class.new(completed_at: log_completed_at) }
    let(:import) { instance_double(GrdaWarehouse::ImportLog, completed_at: import_completed_at) }

    it 'runs from the importer log completion to the import completion' do
      expect(importer_log.post_processing_time(import)).to eq('30 minutes - 9:00 am to  9:30 am')
    end

    it 'is nil until the importer log has completed' do
      expect(described_class.new.post_processing_time(import)).to be_nil
    end

    it 'is nil until the import has completed' do
      expect(importer_log.post_processing_time(instance_double(GrdaWarehouse::ImportLog, completed_at: nil))).to be_nil
    end
  end
end
