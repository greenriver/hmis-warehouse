###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::CohortClient, type: :model do
  describe '#pii_provider' do
    let!(:user) { create(:acl_user) }
    let!(:cohort) { create(:cohort) }
    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
    let!(:unrestricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
    let!(:restricted_cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: restricted_destination_client) }
    let!(:open_cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: unrestricted_destination_client) }

    before do
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    it 'redacts a restricted client regardless of the viewer, and leaves an unrestricted client visible' do
      expect(restricted_cohort_client.pii_provider(user: user).full_name).to eq('Name Redacted')
      expect(open_cohort_client.pii_provider(user: user).full_name).to eq('Open Client')
    end

    context 'mode: :download' do
      # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
      # independent of each example's DB transaction rollback — without this, this context's
      # `include_pii_in_detail_downloads` changes can leak into a later example regardless of run order.
      after { GrdaWarehouse::Config.invalidate_cache }

      it 'redacts a restricted client regardless of the PII-download toggle' do
        GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

        expect(restricted_cohort_client.pii_provider(user: user, mode: :download).full_name).to eq('Name Redacted')
      end

      it 'reveals an unrestricted client only when the PII-download toggle is on' do
        GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
        expect(open_cohort_client.pii_provider(user: user, mode: :download).full_name).to eq('Open Client')

        GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
        GrdaWarehouse::Config.invalidate_cache
        expect(open_cohort_client.pii_provider(user: user, mode: :download).full_name).to eq('Name Redacted')
      end
    end
  end
end
