###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisStructure::Base, type: :model do
  let(:data_source) { create(:source_data_source) }
  let(:client) { create(:grda_warehouse_hud_client, data_source: data_source) }
  let(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }

  def create_staging_row(klass, record: client, **attrs)
    klass.create!(
      PersonalID: record.PersonalID,
      data_source_id: record.data_source_id,
      **attrs,
    )
  end

  def create_importer_row(klass, record: client, **attrs)
    create_staging_row(
      klass,
      record: record,
      importer_log_id: importer_log.id,
      pre_processed_at: importer_log.created_at,
      source_id: record.id,
      source_type: record.class.name,
      **attrs,
    )
  end

  def create_loader_row(klass, **attrs)
    create_staging_row(klass, loader_id: importer_log.id, loaded_at: importer_log.created_at, **attrs)
  end

  describe '#most_recent_import_year' do
    it 'returns nil when no staging row survives in any registered year' do
      expect(client.most_recent_import_year).to be_nil
    end

    it 'returns the newest registered year that has a surviving row' do
      create_importer_row(HmisCsvTwentyTwentyFour::Importer::Client)
      create_importer_row(HmisCsvTwentyTwentySix::Importer::Client)

      expect(client.most_recent_import_year).to eq('2026')
    end

    it 'falls back to a loader row when no importer row survives' do
      create_loader_row(HmisCsvTwentyTwentyFour::Loader::Client)

      expect(client.most_recent_import_year).to eq('2024')
    end

    it 'ignores staging rows for the same HUD key in another data source' do
      other_data_source = create(:source_data_source)
      other_client = create(:grda_warehouse_hud_client, data_source: other_data_source, PersonalID: client.PersonalID)
      create_importer_row(HmisCsvTwentyTwentyFour::Importer::Client)
      create_importer_row(HmisCsvTwentyTwentySix::Importer::Client, record: other_client)

      expect(client.most_recent_import_year).to eq('2024')
    end

    it 'returns nil for a model with no staging tables in older spec years' do
      participation = create(:hud_hmis_participation, data_source: data_source)

      expect(participation).not_to respond_to(:imported_items_2020)
      expect(participation.most_recent_import_year).to be_nil
    end
  end
end
