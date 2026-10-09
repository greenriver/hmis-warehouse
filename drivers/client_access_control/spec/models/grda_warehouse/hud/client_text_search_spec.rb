###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  include_context 'visibility test context'

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    non_window_visible_data_source.update(obey_consent: false)
    non_window_source_client.update!(SSN: '111223333')
  end
  after { GrdaWarehouse::Config.invalidate_cache }
  let!(:config) { create :config_b }

  shared_examples 'limits text search to searchable clients' do
    it 'returns only the name matches the user can search' do
      expect(described_class.text_search('bob', user: user)).to contain_exactly(window_destination_client, both_destination_client)
    end

    it 'drops an SSN match the user cannot search' do
      expect(described_class.text_search('111-22-3333')).to contain_exactly(non_window_destination_client)
      expect(described_class.text_search('111-22-3333', user: user)).to be_empty
    end

    it 'still limits results when the matches exceed the candidate cap' do
      stub_const('GrdaWarehouse::Hud::Client::MAX_SEARCH_CANDIDATES', 1)
      expect(described_class.text_search('bob', user: user)).to contain_exactly(window_destination_client, both_destination_client)
    end

    it 'returns nothing when nothing matches, without building the searchable set' do
      expect(described_class).not_to receive(:searchable_to)
      expect(described_class.text_search('Zzqx', user: user)).to be_empty
    end

    it 'finds a destination by id only through a source the user can search' do
      expect(described_class.text_search(both_destination_client.id.to_s, user: user)).to contain_exactly(both_destination_client)
      expect(described_class.text_search(non_window_destination_client.id.to_s)).to contain_exactly(non_window_destination_client)
      expect(described_class.text_search(non_window_destination_client.id.to_s, user: user)).to be_empty
    end
  end

  shared_examples 'returns every match' do
    it 'returns name matches from every data source' do
      expect(described_class.text_search('bob', user: user)).to contain_exactly(window_destination_client, both_destination_client, non_window_destination_client)
    end

    it 'returns an SSN match outside the window' do
      expect(described_class.text_search('111-22-3333', user: user)).to contain_exactly(non_window_destination_client)
    end
  end

  context 'with access controls for window data sources' do
    before do
      Collection.maintain_system_groups
      setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    end
    let!(:user) { create :acl_user }

    include_examples 'limits text search to searchable clients'
  end

  context 'with a legacy role that searches the window' do
    before do
      AccessGroup.maintain_system_groups
      user.legacy_roles << can_search_window
    end
    let!(:user) { create :user }

    include_examples 'limits text search to searchable clients'
  end

  context 'with a legacy role that searches all clients' do
    before { user.legacy_roles << create(:role, can_search_all_clients: true) }
    let!(:user) { create :user }

    include_examples 'returns every match'
  end

  context 'with the system user' do
    let(:user) { User.system_user }

    include_examples 'returns every match'
  end
end
