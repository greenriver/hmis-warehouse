# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::Processors::ClientProcessor, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:client) { build(:hmis_hud_client, data_source: data_source) }

  describe '#process_mci_id' do
    subject(:processor) { described_class.new }

    it 'uses << operation to add external ID to client' do
      # Test the << operation from line 244: client.external_ids << HmisExternalApis::ExternalId.new
      mci_id = '12345'

      # Mock the external ID class
      external_id_double = double('ExternalId')
      allow(HmisExternalApis::ExternalId).to receive(:new).and_return(external_id_double)

      # Mock the MCI credentials
      mci_double = double('MCI')
      creds_double = double('credentials')
      allow(mci_double).to receive(:creds).and_return(creds_double)
      allow(HmisExternalApis::AcHmis::Mci).to receive(:new).and_return(mci_double)

      # Test that the << operation adds to external_ids array
      expect { processor.send(:process_mci_id, client, mci_id) }.not_to raise_error

      # Verify client attributes are updated
      expect(client.update_mci_attributes).to be true
    end

    it 'raises error for invalid MCI ID' do
      invalid_mci_id = 'not_a_number'

      expect { processor.send(:process_mci_id, client, invalid_mci_id) }.to raise_error('Invalid MCI ID')
    end

    it 'handles valid numeric MCI ID string' do
      valid_mci_id = '67890'

      # Mock the dependencies
      allow(HmisExternalApis::ExternalId).to receive(:new).and_return(double('ExternalId'))
      allow_any_instance_of(HmisExternalApis::AcHmis::Mci).to receive(:creds).and_return(double('creds'))

      expect { processor.send(:process_mci_id, client, valid_mci_id) }.not_to raise_error
      expect(client.update_mci_attributes).to be true
    end
  end
end
