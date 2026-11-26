###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Place, type: :model do
  describe '.lookup' do
    let(:args) { { query: '1 Main St', city: 'Anytown', state: 'MA', postalcode: '01234' } }

    before do
      allow(Geocoder).to receive(:search).and_return([])
      allow(Rails.cache).to receive(:read).with(['Nominatim', 'API PAUSE']).and_return(nil)
      described_class.instance_variable_set(:@places, nil)
    end

    it 'queries the geocoder outside sandbox mode' do
      described_class.lookup(**args)

      expect(Geocoder).to have_received(:search).once
    end

    it 'returns nil, creates no place, and never calls the geocoder in sandbox mode' do
      result = nil
      expect do
        with_sandbox_mode { result = described_class.lookup(**args) }
      end.not_to change(described_class, :count)

      expect(result).to be_nil
      expect(Geocoder).not_to have_received(:search)
    end
  end
end
