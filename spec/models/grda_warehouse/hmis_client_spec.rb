###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HmisClient, type: :model do
  describe '.maintain_client_consent' do
    let(:source_data_source) { create :source_data_source }
    let(:source_client) { create :hud_client, data_source: source_data_source }
    let(:destination_client) { create :hud_client, data_source: create(:destination_data_source) }
    let(:expires_on) { 6.months.from_now.to_date }

    before do
      GrdaWarehouse::Config.delete_all
      create(:config_b, release_duration: 'Use Expiration Date')
      GrdaWarehouse::Config.invalidate_cache
      create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id
      described_class.create!(client: source_client, consent_confirmed_on: 10.days.ago.to_date, consent_expires_on: expires_on)
    end
    after { GrdaWarehouse::Config.invalidate_cache }

    it 'builds the ROI row for the client it grants consent to' do
      expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: destination_client.id)).to be_empty

      described_class.maintain_client_consent

      expect(destination_client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
      expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: destination_client.id)).
        to have_attributes(status: 'full', expires_at: expires_on)
    end
  end
end
