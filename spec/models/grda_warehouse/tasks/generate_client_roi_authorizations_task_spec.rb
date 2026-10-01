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

  # Shared contexts for common test setups
  shared_context 'with release duration settings' do |duration, period = nil|
    before do
      allow(GrdaWarehouse::Hud::Client).to receive(:release_duration).and_return(duration)
      allow(GrdaWarehouse::Hud::Client).to receive(:consent_validity_period).and_return(period) if period
    end
  end

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

      it 'does not change valid records' do
        expect do
          task.perform(batch_size: batch_size)
        end.to(not_change { GrdaWarehouse::ClientRoiAuthorization.count })
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

    context 'when a client has an expired ROI auth record' do
      let!(:client_with_expired_roi) { create(:hud_client, consent_form_signed_on: 2.years.ago) }

      before do
        allow(task).to receive(:roi_status).and_return(GrdaWarehouse::ClientRoiAuthorization::FULL_STATUS)
        allow(task).to receive(:roi_expiry_date).and_return(1.year.ago.to_date)
        create(:client_file_expanded_consent, client: client_with_expired_roi)
      end

      it 'clears consent fields for the expired client' do
        expect { task.perform(batch_size: batch_size) }.
          to change { client_with_expired_roi.reload.consent_form_id }.to(nil)
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

  describe '#roi_expiry_date' do
    let(:client) { create(:hud_client, consent_form_signed_on: today) }
    subject(:expiry_date) { task.send(:roi_expiry_date, client) }

    context 'with one year duration' do
      include_context 'with release duration settings', 'One Year', 1.year

      it { is_expected.to eq(client.consent_form_signed_on + 1.year) }
    end

    context 'with explicit expiration date' do
      include_context 'with release duration settings', 'Use Expiration Date'

      before { client.consent_expires_on = today + 6.months }

      it { is_expected.to eq(client.consent_expires_on) }
    end

    context 'with indefinite duration' do
      include_context 'with release duration settings', 'Indefinite'

      it { is_expected.to be_nil }
    end

    context 'with invalid duration' do
      include_context 'with release duration settings', 'Invalid Duration'

      it 'raises an error' do
        expect { expiry_date }.to raise_error(/unknown release duration/)
      end
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
