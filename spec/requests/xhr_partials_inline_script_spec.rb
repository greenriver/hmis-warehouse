###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

# These partials are fetched over XHR and appended into the page, so an inline
# <script> in them would carry the XHR's CSP nonce rather than the page's and be blocked.
RSpec.describe 'XHR-loaded partials render no inline scripts', type: :request do
  describe 'client dashboard rollups' do
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

    before do
      setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
      sign_in user
    end

    def rollup_html(partial)
      get rollup_client_path(window_destination_client, partial: partial), xhr: true
      Nokogiri::HTML(response.body)
    end

    describe 'services' do
      # Two bed nights in one year and one in another, so the counts vary and the dots render.
      let(:bed_night_dates) { [Date.new(2024, 3, 1), Date.new(2024, 3, 2), Date.new(2025, 3, 1)] }
      let!(:services) do
        bed_night_dates.map do |date|
          create(
            :hud_service,
            data_source_id: window_visible_data_source.id,
            PersonalID: window_source_client.PersonalID,
            EnrollmentID: window_enrollment.EnrollmentID,
            RecordType: HudHelper.util.record_type('Bed Night', true),
            DateProvided: date,
          )
        end
      end

      it 'passes the dots to the Stimulus controller' do
        html = rollup_html(:services)
        expect(html.css('script')).to be_empty

        table = html.at_css('table[data-controller="service-dots"]')
        expect(JSON.parse(table['data-service-dots-dots-value'])).to eq('min' => 1, 'max' => 2, 'points' => [1, 2])
        expect(table.css('[data-service-dots-target="dot"]').size).to eq(2)
      end

      context 'when every year has the same count' do
        let(:bed_night_dates) { [Date.new(2025, 3, 1)] }

        # colorDot needs low < high, so the controller is left off.
        it 'renders the table without the Stimulus controller' do
          html = rollup_html(:services)

          expect(html.css('table td.dot').size).to eq(1)
          expect(html.at_css('[data-controller="service-dots"]')).to be_nil
        end
      end
    end

    describe 'chronic_days' do
      # The chart only renders for a client with service history who has ever been chronic.
      let!(:processed) { create :grda_warehouse_warehouse_clients_processed, client: window_destination_client }
      let!(:chronic) { create :chronic, client: window_destination_client }

      it 'passes the chart URL to the Stimulus controller' do
        html = rollup_html(:chronic_days)
        expect(html.css('script')).to be_empty

        chart = html.at_css('[data-controller="chronic-days-chart"]')
        expect(chart['data-chronic-days-chart-url-value']).to eq(chronic_days_client_path(window_destination_client))
      end
    end
  end
end
