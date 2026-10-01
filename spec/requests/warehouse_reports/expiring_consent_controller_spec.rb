###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::ExpiringConsentController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:report_viewer, can_view_clients: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/expiring_consent', name: 'Expiring Consent') }
  let(:confirmed) { GrdaWarehouse::Hud::Client.full_release_string }

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback.
  after { GrdaWarehouse::Config.invalidate_cache }

  # Fixture dates and the controller's cutoffs are both derived from the clock.
  around { |example| freeze_time { example.run } }

  before do
    GrdaWarehouse::Config.first_or_create.update!(release_duration: release_duration)
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def consented(signed_on:, expires_on: nil, status: nil)
    create(:grda_warehouse_hud_client, consent_form_signed_on: signed_on, consent_expires_on: expires_on, housing_release_status: status)
  end

  # Tables render in page order: unconfirmed, expiring within 30 days, expired.
  def sections
    tables = Nokogiri::HTML(response.body).css('.warehouse-reports__expiring-consent table')
    [:unconfirmed, :expiring, :expired].zip(tables).to_h
  end

  def client_ids_in(table)
    table.css('tbody a').map { |a| a['href'][/\/clients\/(\d+)/, 1].to_i }
  end

  def expiration_cell_for(table, client)
    row = table.css('tbody tr').find { |tr| tr.at_css('a')['href'].match?(/\/clients\/#{client.id}(\D|\z)/) }
    row.css('td')[1].text.strip
  end

  context 'with release_duration Use Expiration Date' do
    let(:release_duration) { 'Use Expiration Date' }
    let!(:expired) { consented(signed_on: 2.years.ago.to_date, expires_on: Date.current - 1.day) }
    let!(:expiring) { consented(signed_on: 1.year.ago.to_date, expires_on: Date.current + 10.days, status: confirmed) }
    let!(:unconfirmed) { consented(signed_on: 1.month.ago.to_date, expires_on: Date.current + 60.days) }
    let!(:current) { consented(signed_on: 1.month.ago.to_date, expires_on: Date.current + 60.days, status: confirmed) }
    # A signed form that has not been confirmed has no expiration date yet.
    let!(:unconfirmed_without_expiration) { consented(signed_on: 1.month.ago.to_date) }
    let!(:confirmed_past_expiration) { consented(signed_on: 2.years.ago.to_date, expires_on: Date.current - 1.day, status: confirmed) }
    let!(:expires_today) { consented(signed_on: 1.year.ago.to_date, expires_on: Date.current) }
    let!(:expires_today_confirmed) { consented(signed_on: 1.year.ago.to_date, expires_on: Date.current, status: confirmed) }
    let!(:expires_in_30_days_confirmed) { consented(signed_on: 1.year.ago.to_date, expires_on: Date.current + 30.days, status: confirmed) }

    it 'places clients by their stored expiration date' do
      get warehouse_reports_expiring_consent_index_path

      expect(response).to have_http_status(:ok)
      expect(client_ids_in(sections[:expired])).to contain_exactly(expired.id, confirmed_past_expiration.id)
      expect(client_ids_in(sections[:expiring])).to contain_exactly(expiring.id, expires_today_confirmed.id)
      expect(client_ids_in(sections[:unconfirmed])).to contain_exactly(unconfirmed.id, unconfirmed_without_expiration.id, expires_today.id)
    end

    it 'shows the stored expiration date' do
      get warehouse_reports_expiring_consent_index_path

      expect(expiration_cell_for(sections[:expiring], expiring)).to eq((Date.current + 10.days).to_s)
    end
  end

  context 'with release_duration One Year' do
    let(:release_duration) { 'One Year' }
    let!(:expired) { consented(signed_on: 13.months.ago.to_date) }
    let!(:expiring) { consented(signed_on: (1.year.ago + 10.days).to_date, status: confirmed) }
    let!(:unconfirmed) { consented(signed_on: 1.month.ago.to_date) }
    let!(:current) { consented(signed_on: 1.month.ago.to_date, status: confirmed) }
    let!(:confirmed_past_expiration) { consented(signed_on: 13.months.ago.to_date, status: confirmed) }
    let!(:expires_today) { consented(signed_on: 1.year.ago.to_date) }
    let!(:expires_today_confirmed) { consented(signed_on: 1.year.ago.to_date, status: confirmed) }
    let!(:expires_in_30_days_confirmed) { consented(signed_on: (1.year.ago + 30.days).to_date, status: confirmed) }

    it 'places clients by signed date plus one year' do
      get warehouse_reports_expiring_consent_index_path

      expect(response).to have_http_status(:ok)
      expect(client_ids_in(sections[:expired])).to contain_exactly(expired.id, confirmed_past_expiration.id)
      expect(client_ids_in(sections[:expiring])).to contain_exactly(expiring.id, expires_today_confirmed.id)
      expect(client_ids_in(sections[:unconfirmed])).to contain_exactly(unconfirmed.id, expires_today.id)
    end

    it 'shows signed date plus one year as the expiration date' do
      get warehouse_reports_expiring_consent_index_path

      expect(expiration_cell_for(sections[:unconfirmed], unconfirmed)).to eq((1.month.ago.to_date + 1.year).to_s)
    end
  end

  context 'with release_duration Two Years' do
    let(:release_duration) { 'Two Years' }
    let!(:expired) { consented(signed_on: 25.months.ago.to_date) }
    let!(:unconfirmed) { consented(signed_on: 13.months.ago.to_date) }

    it 'treats consent signed 13 months ago as unconfirmed rather than expired' do
      get warehouse_reports_expiring_consent_index_path

      expect(response).to have_http_status(:ok)
      expect(client_ids_in(sections[:expired])).to contain_exactly(expired.id)
      expect(client_ids_in(sections[:unconfirmed])).to contain_exactly(unconfirmed.id)
    end
  end

  context 'with release_duration Indefinite' do
    let(:release_duration) { 'Indefinite' }
    let!(:old) { consented(signed_on: 5.years.ago.to_date) }
    let!(:current) { consented(signed_on: 1.month.ago.to_date, status: confirmed) }

    it 'lists every unconfirmed client and never expires consent' do
      get warehouse_reports_expiring_consent_index_path

      expect(response).to have_http_status(:ok)
      expect(client_ids_in(sections[:unconfirmed])).to contain_exactly(old.id)
      expect(client_ids_in(sections[:expiring])).to be_empty
      expect(client_ids_in(sections[:expired])).to be_empty
    end

    it 'leaves the expiration date blank' do
      get warehouse_reports_expiring_consent_index_path

      expect(expiration_cell_for(sections[:unconfirmed], old)).to eq('')
    end
  end
end
