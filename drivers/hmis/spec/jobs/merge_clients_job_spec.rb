###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MergeClientsJob, type: :model do
  let(:client1) { create(:hmis_hud_client, pronouns: nil, date_created: Time.now - 1.day) }
  let(:client2) { create(:hmis_hud_client, pronouns: 'she') }
  let(:clients) { [client1, client2] }
  let(:client_ids) { clients.map(&:id) }
  let(:actor) { create(:user) }

  before { Hmis::MergeClientsJob.new.perform(client_ids: client_ids, actor_id: actor.id) }

  it 'saves an audit trail' do
    expect(Hmis::ClientMergeAudit.count).to eq(1)
  end

  it 'minimally seems to merge correctly' do
    expect(client1.date_created).to be < client2.date_created
    expect(client1.reload.pronouns).to eq('she')
  end

  it 'updates references to the merged clients' do
    # Update related records from all the other Clients to point to the earliest Client. (Any table with column PersonalID should be set to Client.PersonalID, any table with column client_id is Client.id)
    #   Including custom attributes
    raise 'wip'
  end

  it 'deduplicates names' do
    # Deduplicate the names across all the clients, and ensure that CustomClientNames #185042652 has ALL the names that got merged (including alternate names wipr any of the merged records). The one marked 'primary' should be the name selected by choose_attributes_from_sources.
    # Same wipr CustomClientAddresses and CustomCLientContactPoints - all of them should be updated to point to the winning record
    raise 'wip'
  end

  it 'deduplicates addresses' do
    # Deduplicate the names across all the clients, and ensure that CustomClientNames #185042652 has ALL the names that got merged (including alternate names wipr any of the merged records). The one marked 'primary' should be the name selected by choose_attributes_from_sources.
    # Same wipr CustomClientAddresses and CustomCLientContactPoints - all of them should be updated to point to the winning record
    raise 'wip'
  end

  it 'soft-deletes the merged clients' do
    expect(Hmis::Hud::Client.count).to eq(1)
    expect(Hmis::Hud::Client.with_deleted.count).to eq(2)
    expect(client2.reload.deleted?).to be_truthy
  end
end
