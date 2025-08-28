###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::UpdateHousingReleaseStatuses, type: :model do
  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
  end

  describe '#run!' do
    [
      {
        name: 'explicit consent',
        config_factory: :config_b,
        expected_roi_model: 'explicit',
        expected_consent_class: Consent::Default,
      },
      {
        name: 'implicit consent',
        config_factory: :config_va,
        expected_roi_model: 'implicit',
        expected_consent_class: Consent::Implied,
      },
    ].each do |config_scenario|
      context "when config has #{config_scenario[:name]}" do
        let!(:config) { create config_scenario[:config_factory] }
        let(:service) { described_class.new }
        let!(:client) { create :grda_warehouse_hud_client, housing_release_status: 'Invalid Status' }

        let!(:revoked_consent_client) { create :client_with_revoked_consent }
        let!(:expanded_consent_client) { create :client_with_expanded_consent }
        let!(:partial_consent_client) { create :client_with_partial_consent }

        # Create the consent form files for each client
        let!(:revoked_consent_file) { create :client_file_revoked_consent, client: revoked_consent_client }
        let!(:expanded_consent_file) { create :client_file_expanded_consent, client: expanded_consent_client }
        let!(:partial_consent_file) { create :client_file_partial_consent, client: partial_consent_client }

        # Override the housing_release_status after client files are created
        # so we can test that the service correctly updates them
        before do
          revoked_consent_client.update!(housing_release_status: 'Invalid Status')
          expanded_consent_client.update!(housing_release_status: 'Invalid Status')
          partial_consent_client.update!(housing_release_status: 'Invalid Status')
        end

        it "verifies that we are using the #{config_scenario[:name]} model" do
          expect(GrdaWarehouse::Config.get(:roi_model)).to eq(config_scenario[:expected_roi_model])
          expect(GrdaWarehouse::Config.active_consent_class).to eq(config_scenario[:expected_consent_class])
        end

        it 'updates the housing release statuses' do
          service.run!

          # Regular client should become the no_release_string for this consent model
          expect(client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.no_release_string)
          # Revoked consent client should become the revoked_consent_string for this consent model
          expect(revoked_consent_client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.revoked_consent_string)
          # Expanded consent client should become the full_release_string for this consent model
          expect(expanded_consent_client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
          # Partial consent client should become the partial_release_string for this consent model
          expect(partial_consent_client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.partial_release_string)
        end
      end
    end
  end
end
