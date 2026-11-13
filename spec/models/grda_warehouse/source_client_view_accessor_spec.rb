###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::SourceClientViewAccessor do
  include_context 'visibility test context'

  let(:user) { create(:acl_user) }
  subject { described_class.new(user: user) }

  describe '#searchable_clients' do
    context 'with can_search_own_clients only' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:data_sources))
      end
      it 'returns the correct source clients for a window destination client' do
        expect(subject.searchable_clients(window_destination_client)).to include(window_source_client)
        expect(subject.searchable_clients(window_destination_client)).not_to include(non_window_source_client)
      end
      it 'returns the correct source clients for a non-window destination client' do
        expect(subject.searchable_clients(non_window_destination_client)).to include(non_window_source_client)
        expect(subject.searchable_clients(non_window_destination_client)).not_to include(window_source_client)
      end
    end
    context 'without can_search_own_clients' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
      end
      it 'does not return any source clients for a window destination client' do
        expect(subject.searchable_clients(window_destination_client)).to be_empty
      end
      it 'does not return any source clients for a non-window destination client' do
        expect(subject.searchable_clients(non_window_destination_client)).to be_empty
      end
    end
  end

  describe '#viewable_clients' do
    context 'with can_view_clients only' do
      before do
        setup_access_control(user, can_view_clients, Collection.system_collection(:data_sources))
      end
      it 'returns the correct source clients for a window destination client' do
        expect(subject.viewable_clients(window_destination_client)).to include(window_source_client)
        expect(subject.viewable_clients(window_destination_client)).not_to include(non_window_source_client)
      end
      it 'returns the correct source clients for a non-window destination client' do
        expect(subject.viewable_clients(non_window_destination_client)).to include(non_window_source_client)
        expect(subject.viewable_clients(non_window_destination_client)).not_to include(window_source_client)
      end
    end
    context 'without can_view_clients' do
      before do
        setup_access_control(user, can_search_own_clients, Collection.system_collection(:data_sources))
      end
      it 'does not return any source clients for a window destination client' do
        expect(subject.viewable_clients(window_destination_client)).to be_empty
      end
      it 'does not return any source clients for a non-window destination client' do
        expect(subject.viewable_clients(non_window_destination_client)).to be_empty
      end
    end
  end

  describe 'name sets past the preload miss threshold' do
    include PreloadCoverageHelpers

    before do
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:data_sources))
    end

    def link_source(destination, first_name)
      source = create(:grda_warehouse_hud_client, data_source_id: window_visible_data_source.id, FirstName: first_name, LastName: 'Coverage')
      create(
        :grda_warehouse_hud_enrollment,
        data_source_id: window_visible_data_source.id,
        PersonalID: source.PersonalID,
        ProjectID: window_project.ProjectID,
        EntryDate: 1.month.ago.to_date,
      )
      create(
        :warehouse_client,
        data_source_id: window_visible_data_source.id,
        id_in_source: source.PersonalID,
        source_id: source.id,
        destination_id: destination.id,
      )
      source
    end

    it 'names every source client of one destination' do
      destination = create(:grda_warehouse_hud_client, data_source_id: warehouse_data_source.id)
      firsts = Array.new(preload_miss_client_count) { |i| "Alias#{i}" }
      firsts.each { |first| link_source(destination, first) }

      names = subject.searchable_client_names(destination).map(&:value)

      firsts.each { |first| expect(names).to include("#{first} Coverage") }
    end

    it 'names the source client of every destination in a preloaded batch' do
      destinations = Array.new(preload_miss_client_count) do |i|
        create(:grda_warehouse_hud_client, data_source_id: warehouse_data_source.id).tap { |d| link_source(d, "Batch#{i}") }
      end

      subject.preload_searchable_clients(destinations)

      destinations.each_with_index do |destination, i|
        expect(subject.searchable_client_names(destination).map(&:value)).to include("Batch#{i} Coverage")
      end
    end
  end
end
