###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::SourceClientNameSet, type: :model do
  let(:policy) { GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance }
  let(:user) { double('User') }
  let(:destination_client) { double('DestinationClient', patient: nil) }

  def make_source_client(first_name:, last_name:, ds_name: 'Test DS', ds_id: 1)
    data_source = double('DataSource', short_name: ds_name, id: ds_id)
    record = OpenStruct.new(first_name: first_name, last_name: last_name, middle_name: nil)
    pii = GrdaWarehouse::PiiProvider.new(record, policy: policy)
    client = double('SourceClient', data_source: data_source)
    allow(client).to receive(:pii_provider).with(user: user).and_return(pii)
    client
  end

  describe '#each' do
    context 'when all source clients have names' do
      let(:source_clients) do
        [
          make_source_client(first_name: 'Jane', last_name: 'Doe', ds_id: 1),
          make_source_client(first_name: 'Jane', last_name: 'Smith', ds_id: 2),
        ]
      end

      subject { described_class.new(destination_client: destination_client, source_clients: source_clients, user: user) }

      it 'includes all names' do
        expect(subject.to_a.map(&:value)).to contain_exactly('Jane Doe', 'Jane Smith')
      end
    end

    context 'when a source client has no name recorded' do
      let(:source_clients) do
        [
          make_source_client(first_name: 'Jane', last_name: 'Doe', ds_id: 1),
          make_source_client(first_name: nil, last_name: nil, ds_id: 2),
        ]
      end

      subject { described_class.new(destination_client: destination_client, source_clients: source_clients, user: user) }

      it 'excludes the blank-name entry' do
        expect(subject.to_a.map(&:value)).to eq(['Jane Doe'])
      end

      it 'does not raise an error' do
        expect { subject.to_a }.not_to raise_error
      end
    end

    context 'when all source clients have no name recorded' do
      let(:source_clients) do
        [make_source_client(first_name: nil, last_name: nil, ds_id: 1)]
      end

      subject { described_class.new(destination_client: destination_client, source_clients: source_clients, user: user) }

      it 'returns an empty set' do
        expect(subject.to_a).to be_empty
      end
    end
  end
end
