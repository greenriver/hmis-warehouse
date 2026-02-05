# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Internal::CandidateEventWriter, type: :model do
  before(:each) do
    # Stub CandidatePoolBuilder to prevent it from overwriting the unit groups' pools in after_create callbacks
    allow_any_instance_of(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
  end

  let!(:destination_data_source) { create :destination_data_source }

  let(:pool) { create(:hmis_ce_match_candidate_pool) }
  let(:project) { create(:hmis_hud_project) }
  let!(:project_config) { create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true) }
  let!(:unit_group_1) { create(:hmis_unit_group, project: project, candidate_pool: pool) }
  let!(:unit_group_2) { create(:hmis_unit_group, project: project, candidate_pool: pool) }

  let(:writer) { described_class.new(pool) }
  let!(:client) do
    client = create(:hmis_hud_client)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    client
  end
  let(:destination_client) { GrdaWarehouse::Hud::Client.find(client.destination_client.id) }
  let!(:proxy) { create(:hmis_ce_client_proxy, client: destination_client) }

  describe '#call' do
    context "with an 'add' snapshot" do
      let(:snapshot) { Hmis::Ce::Match::Engine::Snapshot.new(client_id: destination_client.id, values: { 'current_age' => 30 }, event_name: 'add') }

      it "creates an 'add' event per unit group" do
        expect do
          writer.call([snapshot], timestamp: Time.current)
        end.to change { Hmis::Ce::Match::CandidateEvent.count }.by(2)

        events = Hmis::Ce::Match::CandidateEvent.last(2)
        expect(events.map(&:event_name).uniq).to eq(['add'])
        expect(events.map(&:snapshot).uniq).to eq([{ 'current_age' => 30 }])
        expect(events.map(&:unit_group_id).sort).to eq([unit_group_1.id, unit_group_2.id].sort)
        expect(events.map(&:candidate_pool_id).uniq).to eq([pool.id])
      end
    end

    context "with a 'remove' snapshot" do
      let(:snapshot) { Hmis::Ce::Match::Engine::Snapshot.new(client_id: destination_client.id, values: { 'current_age' => 10 }, event_name: 'remove') }

      it "creates a 'remove' event per unit group" do
        expect do
          writer.call([snapshot], timestamp: Time.current)
        end.to change { Hmis::Ce::Match::CandidateEvent.count }.by(2)

        events = Hmis::Ce::Match::CandidateEvent.last(2)
        expect(events.map(&:event_name).uniq).to eq(['remove'])
        expect(events.map(&:snapshot).uniq).to eq([{ 'current_age' => 10 }])
        expect(events.map(&:unit_group_id).sort).to eq([unit_group_1.id, unit_group_2.id].sort)
        expect(events.map(&:candidate_pool_id).uniq).to eq([pool.id])
      end
    end

    context 'when pool has no unit groups' do
      let(:pool_without_groups) { create(:hmis_ce_match_candidate_pool) }
      let(:writer_without_groups) { described_class.new(pool_without_groups) }
      let(:snapshot) { Hmis::Ce::Match::Engine::Snapshot.new(client_id: destination_client.id, values: { 'current_age' => 30 }, event_name: 'add') }

      it 'skips event creation and logs a warning' do
        expect(Rails.logger).to receive(:warn).with(include("Pool #{pool_without_groups.id} has no unit groups"))
        expect do
          writer_without_groups.call([snapshot], timestamp: Time.current)
        end.not_to(change { Hmis::Ce::Match::CandidateEvent.count })
      end
    end
  end
end
