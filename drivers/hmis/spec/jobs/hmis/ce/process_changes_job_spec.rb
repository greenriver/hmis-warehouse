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

  before do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  after do
    clear_enqueued_jobs
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
      expect(Hmis::Ce::Match::Engine).not_to receive(:call)
      described_class.perform_now
    end
  end

  context 'with dirty pools' do
    it 'processes dirty pools against all clients' do
      create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)
      all_clients_scope = GrdaWarehouse::Hud::Client.where(id: [client1.id, client2.id, client3.id])

      expect(Hmis::Ce::Match::Engine).to receive(:call).with(pool, an_object_matching(->(scope) { scope.to_a.map(&:id).sort == all_clients_scope.to_a.map(&:id).sort }))
      described_class.perform_now

      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool).processed_version).to eq(1)
    end
  end

  context 'with both dirty pools and dirty clients' do
    let!(:dirty_pool) { create(:hmis_ce_match_candidate_pool) }
    let!(:opportunity_for_dirty_pool) { create(:hmis_ce_opportunity, candidate_pool: dirty_pool) }

    it 'processes dirty pools first, then dirty clients against remaining pools' do
      create(:hmis_ce_change_marker, trackable: dirty_pool)
      create(:hmis_ce_change_marker, trackable: client1)

      all_clients_scope = GrdaWarehouse::Hud::Client.where(id: [client1.id, client2.id, client3.id])
      dirty_client_scope = GrdaWarehouse::Hud::Client.where(id: client1.id)

      # Expect the dirty pool to be processed against ALL clients
      expect(Hmis::Ce::Match::Engine).to receive(:call).with(dirty_pool, an_object_matching(->(scope) { scope.to_a.map(&:id).sort == all_clients_scope.to_a.map(&:id).sort })).once

      # Expect the dirty client to be processed only against the other active (but clean) pool from the shared context
      expect(Hmis::Ce::Match::Engine).to receive(:call).with(pool, an_object_matching(->(scope) { scope.to_a.map(&:id).sort == dirty_client_scope.to_a.map(&:id).sort })).once

      described_class.perform_now

      expect(Hmis::Ce::ChangeMarker.find_by(trackable: dirty_pool).processed_version).to eq(1)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client1).processed_version).to eq(1)
    end
  end
end
