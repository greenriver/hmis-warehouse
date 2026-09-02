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
  let(:cleanup_class) { HmisCsvImporter::PostIngestCleanup::FixIncorrectPersonalIdReferences }
  let(:cleanup) { instance_double(cleanup_class) }

  before do
    HmisCsvTwentyTwentySix::Importer::Project.create!(
      importer_log_id: importer.importer_log.id,
      data_source_id: data_source.id,
      ProjectID: 'P-1',
      OrganizationID: 'O-1',
      ProjectName: 'Test Project',
      pre_processed_at: Time.current,
      source_type: 'HmisCsvTwentyTwentySix::Loader::Project',
      source_id: 1,
    )
    allow(cleanup_class).to receive(:new).and_return(cleanup)
  end

  describe '#post_ingest_cleanup!' do
    it 'runs each configured cleanup against the import data source and its projects' do
      allow(cleanup).to receive(:cleanup!)

      importer.post_ingest_cleanup!

      expect(cleanup_class).to have_received(:new).with(
        importer_log: importer.importer_log,
        data_source: data_source,
        project_ids: ['P-1'],
        version: '2026',
      )
      expect(cleanup).to have_received(:cleanup!)
    end

    it 'reports failures to Sentry without raising' do
      allow(cleanup).to receive(:cleanup!).and_raise(StandardError, 'oh no')
      expect(Sentry).to receive(:capture_exception_with_info).with(
        instance_of(StandardError),
        'Post-ingest cleanup failed',
        hash_including(
          cleanup_class: cleanup_class.name,
          data_source_id: data_source.id,
          importer_log_id: importer.importer_log.id,
          project_ids: ['P-1'],
        ),
      )

      expect { importer.post_ingest_cleanup! }.not_to raise_error
    end
  end
end
