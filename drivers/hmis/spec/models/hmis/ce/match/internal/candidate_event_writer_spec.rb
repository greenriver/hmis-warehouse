# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Internal::CandidateEventWriter, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:pool) { create(:hmis_ce_match_candidate_pool) }
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

      it "creates an 'add' event" do
        expect do
          writer.call([snapshot], timestamp: Time.current)
        end.to change { Hmis::Ce::Match::CandidateEvent.count }.by(1)

        event = Hmis::Ce::Match::CandidateEvent.last
        expect(event.event_name).to eq('add')
        expect(event.snapshot).to eq({ 'current_age' => 30 })
      end
    end

    context "with a 'remove' snapshot" do
      let(:snapshot) { Hmis::Ce::Match::Engine::Snapshot.new(client_id: destination_client.id, values: { 'current_age' => 10 }, event_name: 'remove') }

      it "creates a 'remove' event" do
        expect do
          writer.call([snapshot], timestamp: Time.current)
        end.to change { Hmis::Ce::Match::CandidateEvent.count }.by(1)

        event = Hmis::Ce::Match::CandidateEvent.last
        expect(event.event_name).to eq('remove')
        expect(event.snapshot).to eq({ 'current_age' => 10 })
      end
    end
  end
end
