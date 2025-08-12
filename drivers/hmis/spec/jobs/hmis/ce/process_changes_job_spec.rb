###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_context 'with ce processing setup' do
  let!(:destination_data_source) { create :destination_data_source }
  let!(:client1) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client2) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client3) { create :grda_warehouse_hud_client, data_source: destination_data_source }

  let!(:pool) { create(:hmis_ce_match_candidate_pool) }
  let!(:opportunity) { create(:hmis_ce_opportunity, candidate_pool: pool) }
  let(:now) { Time.current }

  before(:all) { cleanup_test_environment }

  before do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end
end

RSpec.describe Hmis::Ce::ProcessChangesJob, type: :job do
  include ActiveJob::TestHelper
  include_context 'with ce processing setup'

  before do
    Hmis::Ce::ChangeMarker.delete_all
  end

  it 'processes dirty clients' do
    create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 0)
    create(:hmis_ce_change_marker, trackable: client2, current_version: 2, processed_version: 1)
    create(:hmis_ce_change_marker, trackable: client3, current_version: 1, processed_version: 1)

    # Freeze time to check wait time for re-enqueued job
    travel_to now do
      described_class.perform_now(wait_time: 5.minutes)

      # Check markers are processed
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client1).processed_version).to eq(1)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client2).processed_version).to eq(2)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client3).processed_version).to eq(1) # unchanged

      # Check job re-enqueues itself
      enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
      expect(enqueued_job).to be_present
      expect(enqueued_job[:at].to_i).to eq((now + 5.minutes).to_i)
    end
  end

  context 'when no dirty clients' do
    it 'does not call the match engine' do
      create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 1)
      create(:hmis_ce_change_marker, trackable: client2, current_version: 1, processed_version: 1)
      create(:hmis_ce_change_marker, trackable: client3, current_version: 1, processed_version: 1)
      create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 1)
      expect(Hmis::Ce::Match::Engine).not_to receive(:call)
      described_class.perform_now
    end
  end

  context 'with dirty pools' do
    it 'processes dirty pools against all clients' do
      create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)

      # We expect the job to create candidates for all 3 clients.
      expect { described_class.perform_now }.to change(Hmis::Ce::Match::Candidate, :count).by(3)

      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool).processed_version).to eq(1)

      # Verify that candidates were created for the correct clients.
      client_ids = [client1.id, client2.id, client3.id]
      candidate_client_ids = Hmis::Ce::Match::Candidate.joins(:client_proxy).where(candidate_pool: pool).pluck('ce_client_proxies.client_id')
      expect(candidate_client_ids).to match_array(client_ids)
    end
  end

  context 'with untracked records' do
    it 'creates change markers for them' do
      # client2, client3 and pool are untracked
      create(:hmis_ce_change_marker, trackable: client1)
      expect do
        described_class.perform_now
      end.to change(Hmis::Ce::ChangeMarker, :count).by(3) # client2, client3 and pool

      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client2)).to be_present
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client3)).to be_present
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool)).to be_present
    end
  end
end
