###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pii::Scrubber::VersionHistoryPruner do
  around(:example) { |ex| PaperTrailHelper.with_paper_trail { ex.run } }

  def versions_for(record)
    GrdaWarehouse::Version.where(item_id: record.id, item_type: record.class.base_class.name)
  end

  describe '#perform for an STI model' do
    let!(:client_file) { create(:client_file).tap { |f| f.update!(name: 'Renamed') } }
    let!(:hmis_file) do
      file = create(:file, :skip_validate, client: create(:hmis_hud_client))
      file.name = 'Renamed'
      file.save!(validate: false)
      file
    end

    it 'deletes versions of the owner and keeps versions of sibling STI types' do
      expect(versions_for(client_file)).to exist
      expect(versions_for(hmis_file)).to exist

      expect { described_class.new.perform(owner: GrdaWarehouse::ClientFile) }.
        to change { versions_for(client_file).count }.to(0).
        and(not_change { versions_for(hmis_file).count })
    end

    it 'deletes versions orphaned by really_destroy! and keeps versions of live siblings' do
      orphaned_id = client_file.id
      client_file.really_destroy!
      expect(GrdaWarehouse::Version.where(item_id: orphaned_id, item_type: 'GrdaWarehouse::File')).to exist

      expect { described_class.new.perform(owner: GrdaWarehouse::ClientFile) }.
        to change { GrdaWarehouse::Version.where(item_id: orphaned_id, item_type: 'GrdaWarehouse::File').count }.to(0).
        and(not_change { versions_for(hmis_file).count })
    end

    it 'deletes versions of a soft-deleted owner row, with and without ids' do
      other_file = create(:client_file).tap { |f| f.update!(name: 'Renamed') }
      client_file.destroy
      other_file.destroy
      expect(versions_for(client_file)).to exist

      expect { described_class.new.perform(owner: GrdaWarehouse::ClientFile, ids: [client_file.id]) }.
        to change { versions_for(client_file).count }.to(0).
        and(not_change { versions_for(other_file).count })
      expect { described_class.new.perform(owner: GrdaWarehouse::ClientFile) }.
        to change { versions_for(other_file).count }.to(0)
    end

    it 'keeps versions of a soft-deleted sibling' do
      hmis_file.destroy
      expect(versions_for(hmis_file)).to exist

      expect { described_class.new.perform(owner: GrdaWarehouse::ClientFile) }.
        not_to(change { versions_for(hmis_file).count })
    end

    it 'limits deletion to the given ids' do
      other_file = create(:client_file).tap { |f| f.update!(name: 'Renamed') }

      expect { described_class.new.perform(owner: GrdaWarehouse::ClientFile, ids: [client_file.id]) }.
        to change { versions_for(client_file).count }.to(0).
        and(not_change { versions_for(other_file).count })
    end
  end

  describe '#perform for an aliased model' do
    it 'deletes versions recorded under the other alias of the owner' do
      client = create(:hmis_hud_client).tap { |c| c.update!(first_name: 'Changed') }
      versions = GrdaWarehouse::Version.where(item_id: client.id, item_type: 'Hmis::Hud::Client')
      expect(versions).to exist

      described_class.new.perform(owner: GrdaWarehouse::Hud::Client)

      expect(versions).not_to exist
    end
  end
end
