###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::TcHmis::Importers::Loaders::CustomClientDemographicsLoader, type: :model do
  describe 'address lookup' do
    let(:loader) { described_class.allocate }

    before do
      allow(Geocoder).to receive(:search).and_return([])
      allow(Rails.cache).to receive(:read).with(['Nominatim', 'API PAUSE']).and_return(nil)
    end

    it 'queries the geocoder outside sandbox mode' do
      loader.send(:nominatim_lookup, '1 Main St 01234')

      expect(Geocoder).to have_received(:search).once
    end

    it 'returns nil and never calls the geocoder in sandbox mode' do
      result = with_sandbox_mode { loader.send(:nominatim_lookup, '1 Main St 01234') }

      expect(result).to be_nil
      expect(Geocoder).not_to have_received(:search)
    end
  end
end
