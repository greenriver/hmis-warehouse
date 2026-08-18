###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

RSpec.describe 'Client dashboard demographic table', type: :request do
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

  # The demographic table renders one row for the destination client (labeled "Warehouse")
  # and one for each visible source client. Both clients get a distinctive veteran status
  # and a Sex so that a missing cell below is attributable to the configured column set
  # rather than to absent data.
  before do
    window_destination_client.update!(VeteranStatus: 9, Sex: 1, SSN: '123456789')
    window_source_client.update!(VeteranStatus: 9, Sex: 1, SSN: '123456789')
  end

  def store_columns(keys)
    config.update!(client_demographic_columns: keys)
    GrdaWarehouse::Config.invalidate_cache
  end

  # The rollup action renders the bare partial for an XHR request, which is how the
  # dashboard actually loads it. A non-XHR GET falls through to a debugging template that
  # wraps the partial in the full layout.
  def get_demographics(client = window_destination_client)
    get rollup_client_path(client, partial: :demographics), xhr: true
  end

  def demographics_table
    tag = Nokogiri::HTML(response.body).at_css('td.destination-data-source-tag')
    raise "no demographic table in response: #{response.status}" if tag.nil?

    tag.ancestors('table').first
  end

  # Expand colspans so header and body rows can be compared cell for cell. The warehouse
  # row ends in a td with colspan 2, which counts as two columns.
  def cells_in(row)
    row.xpath('./th | ./td').flat_map do |cell|
      Array.new((cell['colspan'] || 1).to_i) { cell.text.squish }
    end
  end

  def header_labels(table)
    cells_in(table.at_css('thead tr'))
  end

  def warehouse_row(table)
    table.at_css('tbody tr')
  end

  def source_row(table, source_client)
    table.at_css("tbody tr[data-test-client-id='#{source_client.id}']")
  end

  def cell_under(table, row, label)
    index = header_labels(table).index(label)
    raise "no #{label.inspect} column; headers were #{header_labels(table).inspect}" if index.nil?

    cells_in(row)[index]
  end

  context 'as a user who can see the client dashboard' do
    before do
      setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      sign_in user
    end

    # GrdaWarehouse::ClientDemographicColumns::DEFAULT_KEYS spelled out as rendered headers,
    # bracketed by the unlabeled ID column and the two unlabeled action columns. Changing this
    # list means every installation that has not configured the table sees a different
    # dashboard after deploy, so treat a failure here as a question about intent.
    it 'renders the default column set when no admin has configured the table' do
      get_demographics

      expect(header_labels(demographics_table)).to eq(
        ['ID', 'Name', 'SSN', 'Age', 'Gender', 'Race', 'Veteran Status', '', ''],
      )
    end

    it 'renders a value from the default columns in both the warehouse row and the source row' do
      get_demographics
      table = demographics_table

      expect(cell_under(table, warehouse_row(table), 'Veteran Status')).to eq('Client prefers not to answer')
      expect(cell_under(table, source_row(table, window_source_client), 'Veteran Status')).to eq('Client prefers not to answer')
    end

    # Stored order is deliberately reversed here: column order comes from
    # ClientDemographicColumns::ALL, never from the order an admin happened to pick.
    it 'orders columns by the registry rather than by the order the keys were stored' do
      store_columns(['veteran_status', 'sex', 'race', 'gender', 'dob', 'ssn', 'name'])

      get_demographics

      expect(header_labels(demographics_table)).to eq(
        ['ID', 'Name', 'SSN', 'Age', 'Sex', 'Gender', 'Race', 'Veteran Status', '', ''],
      )
    end

    # Sex is the one column absent from the defaults, so it exercises the opt-in path end to end.
    it 'renders the HUD sex label in both rows once sex is configured' do
      store_columns(['name', 'sex'])

      get_demographics
      table = demographics_table

      expect(cell_under(table, warehouse_row(table), 'Sex')).to eq('Male')
      expect(cell_under(table, source_row(table, window_source_client), 'Sex')).to eq('Male')
    end

    it 'drops both the header and the value when a column is deselected' do
      # Veteran status is populated on both clients, so its absence proves the config
      # dropped the column rather than the data being empty.
      store_columns(['name', 'ssn', 'dob', 'gender', 'race'])

      get_demographics
      table = demographics_table

      expect(header_labels(table)).not_to include('Veteran Status')
      expect(table.text).not_to include('Client prefers not to answer')
    end

    it 'gives every configured demographic header a calculation tooltip' do
      store_columns(['name', 'ssn', 'dob', 'sex', 'gender', 'race', 'veteran_status'])

      get_demographics
      tooltips = demographics_table.css('thead th span[data-bs-title]')

      expect(tooltips.map { |span| span.text.squish }).to contain_exactly(
        'Name', 'SSN', 'Age', 'Sex', 'Gender', 'Race', 'Veteran Status'
      )
      expect(tooltips.map { |span| span['data-bs-title'].to_s.strip }).to all(be_present)
    end

    describe 'column count parity' do
      # The header and the body rows are built from separate iterations of the same column
      # list, in two different templates. If they ever drift apart the table renders with
      # misaligned cells, so every body row must account for exactly as many columns as the
      # header, counting colspans.
      [
        { description: 'the default column set', keys: nil, expected_columns: 9 },
        { description: 'a reduced column set including sex', keys: ['name', 'sex'], expected_columns: 5 },
      ].each do |scenario|
        it "keeps every row the same width as the header for #{scenario[:description]}" do
          store_columns(scenario[:keys]) if scenario[:keys]

          get_demographics
          table = demographics_table
          headers = header_labels(table)

          expect(headers.length).to eq(scenario[:expected_columns])
          expect(table.css('tbody tr')).not_to be_empty
          table.css('tbody tr').each do |row|
            expect(cells_in(row).length).to eq(headers.length),
                                            "row #{row['data-test-client-id'] || 'warehouse'} had #{cells_in(row).length} columns, header had #{headers.length}"
          end
        end
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
        get_demographics
        expect(cell_under(demographics_table, warehouse_row(demographics_table), 'Veteran Status')).
          to eq('Client prefers not to answer')

        # update_column deliberately skips updated_at, so nothing in the cache key changes
        # and a working fragment cache is required to still serve the old value.
        window_destination_client.update_column(:VeteranStatus, 0)
        get_demographics

        expect(cell_under(demographics_table, warehouse_row(demographics_table), 'Veteran Status')).
          to eq('Client prefers not to answer')
      end

      # The configured keys are part of the cache key, so a config change must not serve the
      # fragment built from the previous column set.
      it 'reflects a changed column set instead of serving the previous fragment' do
        get_demographics
        expect(header_labels(demographics_table)).not_to include('Sex')

        store_columns(['name', 'ssn', 'dob', 'sex', 'gender', 'race', 'veteran_status'])
        get_demographics
        table = demographics_table

        expect(header_labels(table)).to include('Sex')
        expect(cell_under(table, warehouse_row(table), 'Sex')).to eq('Male')
      end
    end
  end

  context 'as a signed-in user without dashboard access' do
    let!(:other_user) { create :acl_user }

    it 'redirects rather than rendering the demographic table' do
      sign_in other_user

      get_demographics

      expect(response).to redirect_to(other_user.my_root_path)
    end
  end
end
