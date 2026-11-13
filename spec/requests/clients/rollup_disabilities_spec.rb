###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

RSpec.describe 'Client dashboard disability rollups', type: :request do
  include_context 'visibility test context'

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
  end

  after do
    GrdaWarehouse::Config.invalidate_cache
  end

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }
  let!(:can_view_hiv_status) { create :role, can_view_hiv_status: true }

  # Both disabilities share the enrollment and InformationDate so the disability-types view
  # aggregates them into a single row; the Physical one is the control that must never be
  # redacted, which is what proves redaction is scoped to HIV rather than to the whole row.
  let!(:hiv_disability) do
    create(
      :hud_disability,
      data_source_id: window_visible_data_source.id,
      PersonalID: window_source_client.PersonalID,
      EnrollmentID: window_enrollment.EnrollmentID,
      DisabilityType: 8,
      DisabilityResponse: 1,
      InformationDate: window_enrollment.EntryDate,
    )
  end
  let!(:physical_disability) do
    create(
      :hud_disability,
      data_source_id: window_visible_data_source.id,
      PersonalID: window_source_client.PersonalID,
      EnrollmentID: window_enrollment.EnrollmentID,
      DisabilityType: 5,
      DisabilityResponse: 1,
      InformationDate: window_enrollment.EntryDate,
    )
  end

  before do
    setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_view_hiv_status, Collection.system_collection(:window_data_sources))
    sign_in user
  end

  def request_disabilities
    get rollup_client_path(window_destination_client, partial: :disabilities), xhr: true
  end

  def request_disability_types
    get rollup_client_path(window_destination_client, partial: :disability_types), xhr: true
  end

  def restrict_window_client!
    Hmis::RestrictedRecord.create!(
      restrictable_id: window_source_client.id,
      restrictable_type: 'Hmis::Hud::Client',
      data_source_id: window_source_client.data_source_id,
      created_by: Hmis::User.find(user.id),
    )
  end

  def response_table
    table = Nokogiri::HTML(response.body).at_css('table')
    raise "no table in response (status #{response.status}): #{response.body.truncate(300)}" if table.nil?

    table
  end

  # Expand colspans so header and body cells line up by index.
  def cells_in(row)
    row.xpath('./th | ./td').flat_map do |cell|
      Array.new((cell['colspan'] || 1).to_i) { cell.text.squish }
    end
  end

  def header_labels(table)
    cells_in(table.at_css('thead tr'))
  end

  def cell_under(table, row, label)
    index = header_labels(table).index(label)
    raise "no #{label.inspect} column; headers were #{header_labels(table).inspect}" if index.nil?

    cells_in(row)[index]
  end

  # _disabilities renders one row per disability record; pick the row by its type label.
  def disabilities_row(table, type_label)
    row = table.css('tbody tr').find { |tr| cell_under(table, tr, 'Disability Type') == type_label }
    raise "no #{type_label.inspect} row" if row.nil?

    row
  end

  # _disability_types renders a th-only group-header row per enrollment followed by one data
  # row per (enrollment, InformationDate); with a single enrollment there is exactly one data row.
  def disability_types_data_row(table)
    rows = table.css('tbody tr').select { |tr| tr.at_css('td') }
    raise "expected one data row, found #{rows.size}" unless rows.size == 1

    rows.first
  end

  describe 'the disabilities rollup' do
    def hiv_response
      table = response_table
      cell_under(table, disabilities_row(table, 'HIV/AIDS'), 'Disability Response')
    end

    def physical_response
      table = response_table
      cell_under(table, disabilities_row(table, 'Physical disability'), 'Disability Response')
    end

    context 'with permission to view HIV status' do
      it 'shows the HIV response for an unrestricted client' do
        request_disabilities

        expect(hiv_response).to eq('Yes')
        expect(physical_response).to eq('Yes')
      end

      it 'redacts only the HIV response once the client is restricted' do
        restrict_window_client!
        request_disabilities

        expect(hiv_response).to eq('redacted')
        expect(physical_response).to eq('Yes')
      end
    end

    context 'without permission to view HIV status' do
      let!(:can_view_hiv_status) { create :role }

      it 'redacts only the HIV response for an unrestricted client' do
        request_disabilities

        expect(hiv_response).to eq('redacted')
        expect(physical_response).to eq('Yes')
      end
    end
  end

  describe 'the disability types rollup' do
    def hiv_cell
      table = response_table
      cell_under(table, disability_types_data_row(table), 'HIV/AIDS')
    end

    def physical_cell
      table = response_table
      cell_under(table, disability_types_data_row(table), 'Physical')
    end

    context 'with permission to view HIV status' do
      it 'shows the HIV response for an unrestricted client' do
        request_disability_types

        expect(hiv_cell).to include('Yes')
        expect(hiv_cell).not_to include('redacted')
        expect(physical_cell).to include('Yes')
      end

      it 'redacts only the HIV response once the client is restricted' do
        restrict_window_client!
        request_disability_types

        expect(hiv_cell).to eq('[redacted]')
        expect(physical_cell).to include('Yes')
      end
    end

    context 'without permission to view HIV status' do
      let!(:can_view_hiv_status) { create :role }

      it 'redacts only the HIV response for an unrestricted client' do
        request_disability_types

        expect(hiv_cell).to eq('[redacted]')
        expect(physical_cell).to include('Yes')
      end
    end

    describe 'with fragment caching turned on' do
      # The test env sets perform_caching false and the cache store to :null_store, so the
      # fragment cache key is inert by default. These examples turn real caching on to assert
      # anything about it, and restore the previous settings afterward.
      around do |example|
        previous_perform_caching = ActionController::Base.perform_caching
        previous_controller_store = ActionController::Base.cache_store
        previous_cache = Rails.cache
        # Fragments are written through the controller's own cache_store, which is
        # resolved from config.cache_store at boot; reassigning Rails.cache is not enough.
        ActionController::Base.perform_caching = true
        ActionController::Base.cache_store = :memory_store
        Rails.cache = ActionController::Base.cache_store
        begin
          example.run
        ensure
          Rails.cache = previous_cache
          ActionController::Base.cache_store = previous_controller_store
          ActionController::Base.perform_caching = previous_perform_caching
        end
      end

      # A control for the example that follows: if the fragment were not actually being
      # cached here, that example would pass no matter what the cache key contained.
      it 'caches the fragment across requests' do
        request_disability_types
        expect(hiv_cell).to include('Yes')

        # update_column skips touching the client, so nothing in the cache key changes and a
        # working fragment cache is required to still serve the old value.
        hiv_disability.update_column(:DisabilityResponse, 0)
        request_disability_types

        expect(hiv_cell).to include('Yes')
      end

      # Marking a client restricted touches neither the client nor any record already in the
      # cache key, so the key must carry an explicit restriction token or a fragment rendered
      # before the restriction keeps serving the real HIV status.
      it 'invalidates the cached fragment when the client becomes restricted' do
        request_disability_types
        expect(hiv_cell).to include('Yes')

        restrict_window_client!
        request_disability_types

        expect(hiv_cell).to eq('[redacted]')
      end
    end
  end
end
