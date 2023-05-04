###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::ProgramInvolvement, type: :model do
  describe 'basics' do
    let(:involvement) { HmisExternalApis::AcHmis::ProgramInvolvement.new({}) }

    before { involvement.validate_request! }

    it 'gracefully handles no inputs' do
      expect(involvement.ok?).to be_falsy
    end

    it 'returns an involvements payload' do
      expect(JSON.parse(involvement.to_json)['involvements']).to eq []
    end
  end
end
