###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::Importer, type: :model do
  let(:data_source) { create(:importer_fix_incorrect_personal_ids_ds) }
  let(:loader_log) do
    HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: data_source.id, status: :loaded, version: '2026')
  end
  let(:importer) { described_class.new(loader_id: loader_log.id, data_source_id: data_source.id) }

  before do
    allow(importer).to receive(:involved_project_ids).and_return(['P-1'])
    allow_any_instance_of(HmisCsvImporter::PostIngestCleanup::FixIncorrectPersonalIdReferences).
      to receive(:cleanup!).and_raise(StandardError, 'oh no')
  end

  describe '#post_ingest_cleanup!' do
    it 'reports failures to Sentry without raising' do
      expect(Sentry).to receive(:capture_exception_with_info).with(
        instance_of(StandardError),
        'Post-ingest cleanup failed',
        hash_including(
          cleanup_class: 'HmisCsvImporter::PostIngestCleanup::FixIncorrectPersonalIdReferences',
          data_source_id: data_source.id,
          importer_log_id: importer.importer_log.id,
          project_ids: ['P-1'],
        ),
      )

      expect { importer.post_ingest_cleanup! }.not_to raise_error
    end
  end

  describe '#import!' do
    before do
      allow(importer).to receive(:start_import) do
        importer.instance_variable_set(:@started_at, Time.current)
      end
      allow(importer).to receive(:analyze_tables)
      allow(importer).to receive(:pre_process!)
      allow(importer).to receive(:validate_data_set!)
      allow(importer).to receive(:aggregate!)
      allow(importer).to receive(:cleanup_data_set!)
      allow(importer).to receive(:precalculate_change_counts)
      allow(importer).to receive(:notify_of_import_status)
      allow(importer).to receive(:should_pause?).and_return(false)
      allow(importer).to receive(:ingest!)
      allow(importer).to receive(:invalidate_aggregated_enrollments!)
      allow(importer).to receive(:post_process)
      allow(Sentry).to receive(:capture_exception_with_info)
    end

    it 'marks the import complete even when post-ingest cleanup fails' do
      importer.import!

      expect(importer.importer_log.reload.status).to eq('complete')
    end
  end
end
