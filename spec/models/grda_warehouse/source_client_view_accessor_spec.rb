# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::SourceClientViewAccessor do
  include_context 'visibility test context'

  let(:user) { create(:acl_user) }
  subject { described_class.new(user: user) }

  before do
    setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
    setup_access_control(user, can_search_own_clients, Collection.system_collection(:data_sources))
  end

  describe '#searchable_clients' do
    it 'returns the correct source clients for a window destination client' do
      expect(subject.searchable_clients(window_destination_client)).to include(window_source_client)
    end
    it 'returns the correct source clients for a non-window destination client' do
      expect(subject.searchable_clients(non_window_destination_client)).to include(non_window_source_client)
    end
  end

  describe '#viewable_clients' do
    it 'returns the correct source clients for a window destination client' do
      expect(subject.viewable_clients(window_destination_client)).to include(window_source_client)
    end
    it 'returns the correct source clients for a non-window destination client' do
      expect(subject.viewable_clients(non_window_destination_client)).to include(non_window_source_client)
    end
  end
end
