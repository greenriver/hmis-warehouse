require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask, type: :model do
  let(:task) { described_class.new }
  let(:today) { Date.current }

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
  end

  describe '#process_client' do
    let(:client) { create(:hud_client, consent_form_signed_on: today) }
    subject(:processed_result) { task.send(:process_client, client) }

    context 'with different release statuses' do
      [
        {
          scenario: 'full release',
          release_valid: true,
          revoked_consent: false,
          partial_release: false,
          expected_status: 'full',
        },
        {
          scenario: 'revoked consent',
          release_valid: false,
          revoked_consent: true,
          partial_release: false,
          expected_status: 'revoked',
        },
        {
          scenario: 'partial release',
          release_valid: false,
          revoked_consent: false,
          partial_release: true,
          expected_status: 'partial',
        },
      ].each do |test_case|
        context "when client has #{test_case[:scenario]}" do
          before do
            allow(client).to receive(:release_valid?).and_return(test_case[:release_valid])
            allow(client).to receive(:revoked_consent?).and_return(test_case[:revoked_consent])
            allow(client).to receive(:partial_release?).and_return(test_case[:partial_release])
          end

          it 'returns correct status' do
            expect(processed_result[:status]).to eq(test_case[:expected_status])
          end
        end
      end
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
end
