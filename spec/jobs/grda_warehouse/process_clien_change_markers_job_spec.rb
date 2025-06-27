###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ProcessClientChangeMarkersJob, type: :job do
  include ActiveJob::TestHelper

  let!(:destination_data_source) { create :destination_data_source }
  let!(:client1) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client2) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client3) { create :grda_warehouse_hud_client, data_source: destination_data_source }

  let!(:marker1) { create :grda_warehouse_client_change_marker, client_id: client1.id, current_version: 1, processed_version: 0 }
  let!(:marker2) { create :grda_warehouse_client_change_marker, client_id: client2.id, current_version: 2, processed_version: 1 }
  let!(:marker3_processed) { create :grda_warehouse_client_change_marker, client_id: client3.id, current_version: 1, processed_version: 1 }

  let!(:pool) { create(:hmis_ce_match_candidate_pool) }
  let!(:opportunity) { create(:hmis_ce_opportunity, candidate_pool: pool) }
  let(:now) {Time.current}

  before do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  after do
    clear_enqueued_jobs
  end

  it 'processes dirty clients' do
    # Freeze time to check wait time for re-enqueued job
    travel_to now do
      described_class.perform_now

      # Check markers are processed
      expect(marker1.reload.processed_version).to eq(1)
      expect(marker2.reload.processed_version).to eq(2)
      expect(marker3_processed.reload.processed_version).to eq(1) # unchanged

      # Check job re-enqueues itself
      enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
      expect(enqueued_job).to be_present
      expect(enqueued_job[:at].to_i).to eq((now + 5.minutes).to_i)
    end
  end

  context 'when no dirty clients' do
    before do
      GrdaWarehouse::ClientChangeMarker.update_all('processed_version = current_version')
    end

    it 'does not call the match engine' do
      expect(Hmis::Ce::Match::Engine).not_to receive(:call)
      described_class.perform_now
    end
  end
end
