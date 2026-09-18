###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::ClientRetentionController, type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) { create(:client_retention_report) }

  let!(:warehouse_ds) { create(:destination_data_source) }
  let!(:source_ds) { create(:source_data_source) }
  # Newest activity 30 days short of the 7-year window, so this identity is about to expire.
  let!(:expiring_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, FirstName: 'Zzexpiring', LastName: 'Zzsoon', DateUpdated: 8.years.ago) }
  let!(:expiring_source) { create(:grda_warehouse_hud_client, data_source: source_ds, FirstName: 'Zzexpiring', LastName: 'Zzsoon', DateUpdated: 7.years.ago + 30.days) }
  # Active last year: never expiring soon.
  let!(:active_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, DateUpdated: 1.year.ago) }
  let!(:active_source) { create(:grda_warehouse_hud_client, data_source: source_ds, DateUpdated: 1.year.ago) }
  let!(:marked_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, FirstName: 'Zzmarked', LastName: 'Zzclient', DateUpdated: 10.years.ago) }
  let!(:older_run) { GrdaWarehouse::ClientRetentionRun.create!(started_at: 2.days.ago, completed_at: 2.days.ago + 10.minutes, global_retention_years: 7, evaluated_count: 2, marked_count: 1) }
  let!(:newer_run) { GrdaWarehouse::ClientRetentionRun.create!(started_at: 1.hour.ago, completed_at: 30.minutes.ago, global_retention_years: 7, evaluated_count: 2, marked_count: 0) }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: expiring_destination.id, source_id: expiring_source.id, data_source_id: source_ds.id, id_in_source: expiring_source.PersonalID)
    GrdaWarehouse::WarehouseClient.create!(destination_id: active_destination.id, source_id: active_source.id, data_source_id: source_ds.id, id_in_source: active_source.PersonalID)
    GrdaWarehouse::ClientRetentionLogEntry.create!(run: older_run, action: 'marked', destination_client_id: marked_destination.id, source_clients: [{ 'client_id' => 999_001, 'data_source_id' => source_ds.id, 'personal_id' => 'P1' }], last_activity_on: 10.years.ago.to_date, retention_years: 7, created_at: 2.days.ago)
    GrdaWarehouse::ClientRetentionLogEntry.create!(run: newer_run, action: 'unmarked', destination_client_id: active_destination.id, created_at: 30.minutes.ago)
    GrdaWarehouse::Config.first_or_create.update!(client_retention_years: 7)
    GrdaWarehouse::Config.invalidate_cache
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  # Row order in a rendered table, by the position of each client's link.
  def link_positions(body, *client_ids)
    client_ids.map { |id| body.index(%(href="#{client_path(id)}")) }
  end

  context 'without the report assigned' do
    it 'refuses every tab' do
      [warehouse_reports_client_retention_index_path, expired_warehouse_reports_client_retention_index_path, runs_warehouse_reports_client_retention_index_path].each do |path|
        get path

        expect(response).to redirect_to(user.my_root_path)
        expect(response.body).not_to include('Records Expiring Soon')
      end
    end
  end

  context 'with the report assigned' do
    before { collection.set_viewables(reports: [report_definition.id]) }

    describe 'Records Expiring Soon' do
      it 'lists only identities whose window ends within 90 days, by id and never by name' do
        get warehouse_reports_client_retention_index_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(client_path(expiring_destination.id))
        expect(response.body).to include(expiring_source.id.to_s)
        expect(response.body).not_to include(client_path(active_destination.id))
        expect(response.body).not_to include('Zzexpiring')
      end

      it 'shows the disabled notice and no clients when retention is off' do
        GrdaWarehouse::Config.first_or_create.update!(client_retention_years: nil)
        GrdaWarehouse::Config.invalidate_cache

        get warehouse_reports_client_retention_index_path

        expect(response.body).to include('Client data retention is disabled')
        expect(response.body).not_to include(client_path(expiring_destination.id))
      end
    end

    describe 'Expired Records' do
      it 'lists log entries newest first, by id and never by name' do
        get expired_warehouse_reports_client_retention_index_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('999001')
        expect(response.body).not_to include('Zzmarked')
        newer, older = link_positions(response.body, active_destination.id, marked_destination.id)
        expect(newer).to be < older
      end

      it 'filters to one warehouse client' do
        get expired_warehouse_reports_client_retention_index_path, params: { destination_client_id: marked_destination.id }

        expect(response.body).to include(client_path(marked_destination.id))
        expect(response.body).not_to include(client_path(active_destination.id))
      end
    end

    describe 'Retention Run History' do
      it 'lists runs newest first with their counts' do
        get runs_warehouse_reports_client_retention_index_path

        expect(response).to have_http_status(:ok)
        expect(response.body.index(newer_run.started_at.to_fs(:db))).to be < response.body.index(older_run.started_at.to_fs(:db))
        expect(response.body).to include('7 years')
      end
    end
  end
end
