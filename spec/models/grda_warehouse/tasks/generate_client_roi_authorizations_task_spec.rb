###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask, type: :model do
  let(:task) { described_class.new }
  let(:today) { Date.current }

  # Config.get caches across examples; pin an Indefinite release duration
  before do
    GrdaWarehouse::Config.delete_all
    create(:config_b)
    GrdaWarehouse::Config.invalidate_cache
  end
  after { GrdaWarehouse::Config.invalidate_cache }

  describe '#perform' do
    let!(:destination_clients) do
      5.times.map { create(:hud_client, consent_form_signed_on: today) }
    end

    # set a batch size lower than total number of clients to check interactions
    let(:batch_size) { 3 }

    before do
      allow(task).to receive(:roi_status).and_return('full_status')
    end

    context 'with no existing ROI records' do
      it 'creates appropriate auth records' do
        expect do
          task.perform(batch_size: batch_size)
        end.to change { GrdaWarehouse::ClientRoiAuthorization.count }.by(5)
      end
    end

    context 'with existing ROI records' do
      before do
        destination_clients.map do |client|
          GrdaWarehouse::ClientRoiAuthorization.create!(
            destination_client_id: client.id,
            status: 'full_status',
          )
        end
      end

      context 'when a client is orphaned' do
        before do
          GrdaWarehouse::Hud::Client.where(id: destination_clients.last.id).delete_all
        end

        it 'removes the orphaned auth record' do
          expect do
            task.perform(batch_size: batch_size)
          end.to change { GrdaWarehouse::ClientRoiAuthorization.count }.by(-1)
        end
      end

      context 'when client loses roi status' do
        before do
          allow(task).to receive(:roi_status) do |client|
            client.id == destination_clients.last.id ? nil : 'full_status'
          end
        end

        it 'removes the auth record' do
          expect do
            task.perform(batch_size: batch_size)
          end.to change { GrdaWarehouse::ClientRoiAuthorization.count }.by(-1)
        end
      end
    end

    context 'when client loses roi status and has a consent file' do
      let!(:client_losing_roi) { destination_clients.last }

      before do
        allow(task).to receive(:roi_status) do |client|
          client.id == client_losing_roi.id ? nil : 'full_status'
        end
        create(:client_file_expanded_consent, client: client_losing_roi)
      end

      it 'clears consent fields for client that lost ROI status' do
        expect { task.perform(batch_size: batch_size) }.
          to change { client_losing_roi.reload.consent_form_id }.to(nil)
      end
    end
  end

  describe 'authorization status' do
    let(:client) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source), consent_form_signed_on: today }

    def roi_row
      GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)
    end

    it 'is full for a full release' do
      client.update_columns(housing_release_status: GrdaWarehouse::Hud::Client.full_release_string)
      described_class.rebuild_clients([client.id])
      expect(roi_row.status).to eq('full')
    end

    it 'is partial for a partial release' do
      client.update_columns(housing_release_status: Consent::Default.partial_release_string)
      described_class.rebuild_clients([client.id])
      expect(roi_row.status).to eq('partial')
    end

    context 'when the client has no recognized release status under implied consent' do
      before do
        GrdaWarehouse::Config.delete_all
        create(:config_va)
        GrdaWarehouse::Config.invalidate_cache
        client.update_columns(housing_release_status: '')
      end

      it 'resets the client to implied consent and builds the partial row in the same rebuild' do
        described_class.rebuild_clients([client.id])
        expect(client.reload.housing_release_status).to eq(Consent::Implied.no_release_string)
        expect(roi_row.status).to eq('partial')
      end
    end

    context 'when implied consent is revoked under a One Year release duration' do
      before do
        GrdaWarehouse::Config.delete_all
        create(:config_va, release_duration: 'One Year')
        GrdaWarehouse::Config.invalidate_cache
        create :client_file_revoked_consent, client: client
        client.invalidate_consent!(hr_status: Consent::Implied.revoked_consent_string)
      end

      it 'is revoked with no expiry, although revocation cleared the signature date' do
        expect(client.reload.consent_form_signed_on).to be_nil
        described_class.rebuild_clients([client.id])
        expect(roi_row).to have_attributes(status: 'revoked', expires_at: nil)
      end
    end

    context 'when a full release has no expiration date under a Use Expiration Date release duration' do
      before do
        GrdaWarehouse::Config.delete_all
        create(:config_b, release_duration: 'Use Expiration Date')
        GrdaWarehouse::Config.invalidate_cache
        client.update_columns(housing_release_status: GrdaWarehouse::Hud::Client.full_release_string, consent_form_id: 1, consent_expires_on: nil)
      end

      it 'builds no row and clears the consent columns on the client' do
        described_class.rebuild_clients([client.id])
        expect(roi_row).to be_nil
        expect(client.reload).to have_attributes(housing_release_status: nil, consent_form_id: nil, consent_form_signed_on: nil)
      end

      it 'reads the client once under Consent::Default' do
        client_reads = sql_during { described_class.rebuild_clients([client.id]) }.grep(/SELECT .* FROM "Client"/)
        expect(client_reads.size).to eq(1)
        expect(client_reads.first).to include('FOR UPDATE')
      end
    end
  end

  describe 'expired One Year release' do
    let(:client) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source) }

    def roi_row
      GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)
    end

    def perform_under(config_factory)
      GrdaWarehouse::Config.delete_all
      create(config_factory, release_duration: 'One Year')
      GrdaWarehouse::Config.invalidate_cache
      client.update_columns(
        housing_release_status: GrdaWarehouse::Hud::Client.full_release_string,
        consent_form_signed_on: 2.years.ago.to_date,
        consent_form_id: 1,
      )
      task._perform(client_ids: [client.id])
    end

    it 'falls back to an undated partial row and implied consent under Consent::Implied' do
      perform_under(:config_va)
      expect(roi_row).to have_attributes(status: 'partial', starts_at: nil, expires_at: nil)
      expect(client.reload).to have_attributes(housing_release_status: Consent::Implied.no_release_string, consent_form_id: nil)
    end

    it 'deletes the row and clears the release under Consent::Default' do
      perform_under(:config_b)
      expect(roi_row).to be_nil
      expect(client.reload).to have_attributes(housing_release_status: nil, consent_form_id: nil)
    end
  end

  describe 'deadlock retry' do
    let!(:client) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source), housing_release_status: GrdaWarehouse::Hud::Client.full_release_string }

    it 'retries a batch once after a deadlock' do
      calls = 0
      allow(task).to receive(:rebuild_batch).and_wrap_original do |original, *args|
        calls += 1
        raise ActiveRecord::Deadlocked, 'deadlock detected' if calls == 1

        original.call(*args)
      end
      task._perform
      expect(calls).to eq(2)
      expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: client.id).pluck(:status)).to eq(['full'])
    end

    it 'raises when the retried batch deadlocks again' do
      allow(task).to receive(:rebuild_batch).and_raise(ActiveRecord::Deadlocked, 'deadlock detected')
      expect { task._perform }.to raise_error(ActiveRecord::Deadlocked)
    end
  end

  describe 'ROI row dates by release duration' do
    let(:signed_on) { today - 10.days }
    let(:expires_on) { today + 6.months }
    let(:client) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source) }

    def rebuild_under(release_duration)
      GrdaWarehouse::Config.delete_all
      create(:config_b, release_duration: release_duration)
      GrdaWarehouse::Config.invalidate_cache
      client.update_columns(
        housing_release_status: GrdaWarehouse::Hud::Client.full_release_string,
        consent_form_signed_on: signed_on,
        consent_expires_on: expires_on,
      )
      described_class.rebuild_clients([client.id])
      GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)
    end

    it 'expires one year after signing under One Year' do
      expect(rebuild_under('One Year')).to have_attributes(starts_at: signed_on, expires_at: signed_on + 1.year)
    end

    it 'expires two years after signing under Two Years' do
      expect(rebuild_under('Two Years')).to have_attributes(starts_at: signed_on, expires_at: signed_on + 2.years)
    end

    it 'expires on the client expiration date under Use Expiration Date' do
      expect(rebuild_under('Use Expiration Date')).to have_attributes(starts_at: signed_on, expires_at: expires_on)
    end

    it 'never expires under Indefinite' do
      expect(rebuild_under('Indefinite')).to have_attributes(starts_at: signed_on, expires_at: nil)
    end

    it 'raises for an unknown release duration' do
      expect { rebuild_under('Invalid Duration') }.to raise_error(RuntimeError, 'unknown release duration "Invalid Duration"')
    end
  end

  describe '.rebuild_clients' do
    let!(:target) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source), housing_release_status: GrdaWarehouse::Hud::Client.full_release_string }
    let!(:bystander) { create :grda_warehouse_hud_client, data_source: target.data_source, housing_release_status: GrdaWarehouse::Hud::Client.full_release_string }

    it 'builds rows only for the given clients' do
      described_class.rebuild_clients([target.id])
      expect(GrdaWarehouse::ClientRoiAuthorization.pluck(:destination_client_id, :status)).to contain_exactly([target.id, 'full'])
    end

    it 'removes the row when the client no longer has consent' do
      described_class.rebuild_clients([target.id])
      target.update_columns(housing_release_status: nil)
      described_class.rebuild_clients([target.id])
      expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: target.id)).to be_empty
    end

    # Transactional fixtures turn the outermost application transaction into a savepoint
    it 'holds the client row locks until the authorization rows are written' do
      statements = sql_during { described_class.rebuild_clients([target.id]) }
      lock_at = statements.index { |sql| sql.match?(/FROM "Client".*FOR UPDATE/m) }
      write_at = statements.index { |sql| sql.include?('INSERT INTO "client_roi_authorizations"') }
      savepoint_at = statements[0...lock_at].rindex { |sql| sql.start_with?('SAVEPOINT ') }
      expect([lock_at, write_at, savepoint_at]).to all(be_an(Integer))

      release_at = statements.index.with_index { |sql, i| i > lock_at && sql == "RELEASE #{statements[savepoint_at]}" }
      expect(write_at).to be > lock_at
      expect(release_at).to be > write_at
    end
  end

  describe '#_perform' do
    it 'rebuilds every destination client under row locks' do
      client = create :grda_warehouse_hud_client, data_source: create(:destination_data_source), housing_release_status: GrdaWarehouse::Hud::Client.full_release_string
      expect(sql_during { described_class.new._perform }).to include(a_string_matching(/FROM "Client".*FOR UPDATE/m))
      expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: client.id).pluck(:status)).to eq(['full'])
    end

    context 'with a Use Expiration Date release duration' do
      let(:client) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source) }

      around { |example| freeze_time { example.run } }

      before do
        GrdaWarehouse::Config.delete_all
        create(:config_b, release_duration: 'Use Expiration Date')
        GrdaWarehouse::Config.invalidate_cache
        client.update_columns(
          housing_release_status: GrdaWarehouse::Hud::Client.full_release_string,
          consent_form_signed_on: today - 30.days,
          consent_form_id: 1,
        )
      end

      it 'keeps the row and the consent columns on the expiration date' do
        client.update_columns(consent_expires_on: today)
        described_class.new._perform(client_ids: [client.id])
        expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)).to have_attributes(status: 'full', expires_at: today)
        expect(client.reload).to have_attributes(consent_form_id: 1, consent_expires_on: today)
      end

      it 'deletes the row and clears the consent columns the day after the expiration date' do
        client.update_columns(consent_expires_on: today - 1.day)
        described_class.new._perform(client_ids: [client.id])
        expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: client.id)).to be_empty
        expect(client.reload).to have_attributes(consent_form_id: nil, housing_release_status: nil, consent_expires_on: nil)
      end
    end
  end

  # Warehouse connection only; models such as Translation write through a separate connection
  def sql_during(&block)
    connection = GrdaWarehouseBase.connection
    statements = []
    recorder = ->(*, payload) { statements << payload[:sql] if payload[:connection].equal?(connection) }
    ActiveSupport::Notifications.subscribed(recorder, 'sql.active_record', &block)
    statements
  end
end
