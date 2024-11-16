# spec/models/grda_warehouse/tasks/generate_client_roi_authorizations_task_spec.rb
require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask, type: :model do
  let(:task) { described_class.new }

  describe '#process_client' do
    let(:client) { create(:hud_client) }

    context 'when client has valid release' do
      before do
        allow(client).to receive(:release_valid?).and_return(true)
        allow(client).to receive(:revoked_consent?).and_return(false)
        allow(client).to receive(:partial_release?).and_return(false)
      end

      it 'returns authorization attributes with full status' do
        result = task.send(:process_client, client)
        expect(result[:status]).to eq(GrdaWarehouse::ClientRoiAuthorization::FULL_STATUS)
      end
    end

    context 'when client has revoked consent' do
      before do
        allow(client).to receive(:revoked_consent?).and_return(true)
      end

      it 'returns authorization attributes with revoked status' do
        result = task.send(:process_client, client)
        expect(result[:status]).to eq(GrdaWarehouse::ClientRoiAuthorization::REVOKED_STATUS)
      end
    end

    context 'when client has partial release' do
      before do
        allow(client).to receive(:revoked_consent?).and_return(false)
        allow(client).to receive(:partial_release?).and_return(true)
      end

      it 'returns authorization attributes with partial status' do
        result = task.send(:process_client, client)
        expect(result[:status]).to eq(GrdaWarehouse::ClientRoiAuthorization::PARTIAL_STATUS)
      end
    end
  end

  describe '#roi_expiry_date' do
    let(:client) { create(:hud_client, consent_form_signed_on: Date.current) }

    context 'when release duration is One Year' do
      before do
        allow(GrdaWarehouse::Hud::Client).to receive(:release_duration).and_return('One Year')
        allow(GrdaWarehouse::Hud::Client).to receive(:consent_validity_period).and_return(1.year)
      end

      it 'returns date one year from signing' do
        expect(task.send(:roi_expiry_date, client)).to eq(client.consent_form_signed_on + 1.year)
      end
    end

    context 'when release duration is Use Expiration Date' do
      before do
        allow(GrdaWarehouse::Hud::Client).to receive(:release_duration).and_return('Use Expiration Date')
        client.consent_expires_on = Date.current + 6.months
      end

      it 'returns the explicit expiration date' do
        expect(task.send(:roi_expiry_date, client)).to eq(client.consent_expires_on)
      end
    end

    context 'when release duration is Indefinite' do
      before do
        allow(GrdaWarehouse::Hud::Client).to receive(:release_duration).and_return('Indefinite')
      end

      it 'returns nil' do
        expect(task.send(:roi_expiry_date, client)).to be_nil
      end
    end
  end
end
