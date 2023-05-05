###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::ClientInvolvement, type: :model do
  describe 'basics' do
    let(:involvement) { HmisExternalApis::AcHmis::ClientInvolvement.new({}) }

    before { involvement.validate_request! }

    it 'gracefully handles no inputs' do
      expect(involvement.ok?).to be_falsy
    end

    it 'returns an involvements payload' do
      expect(JSON.parse(involvement.to_json)['involvements']).to eq []
    end
  end

  describe 'request' do
    let(:enrollment) { create(:hmis_hud_enrollment) }

    let(:client) { enrollment.client }

    let(:mci_id) do
      external_id = create(:mci_external_id, source: client)
      external_id.value
    end

    let(:params) do
      {
        start_date: '1990-01-01',
        end_date: '4023-01-01',
        mci_ids: [mci_id],
      }
    end

    let(:involvement) { HmisExternalApis::AcHmis::ClientInvolvement.new(params) }

    before { involvement.validate_request! }

    it 'works' do
      involvements = JSON.parse(involvement.to_json)['involvements']

      expect(involvements.length).to eq(1)
      expect(involvements[0]['mci_id']).to eq(mci_id)
    end
  end
end
