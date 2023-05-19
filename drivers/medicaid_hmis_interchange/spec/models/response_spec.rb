###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'MedicaidHmisInterchange::Health::Response', type: :model do
  it 'parses the response' do
    response = "ID_MEDICAID|RDC_HOMELESS_FLAG|FIELD|CDE_ERROR|MSG\nID-1||Field 2|2|Note\nID-2|Y|Field 1|3|Note"
    problems = MedicaidHmisInterchange::Health::Response.new(error_report: response).problems

    expect(problems.size).to eq(2)
    expect(problems.first[:medicaid_id]).to eq('ID-1')
    expect(problems.first[:error_code]).to eq('2')
    expect(problems.last[:medicaid_id]).to eq('ID-2')
  end

  describe 'with unexpected ids' do
    let!(:submission) { create :mhx_submission }
    let!(:id3) { create :mhx_external_id, identifier: 'ID-3' }

    it "doesn't touch the external ids" do
      response = "ID_MEDICAID|RDC_HOMELESS_FLAG|FIELD|CDE_ERROR|MSG\nID-1||Field 2|2|Note\nID-2|Y|Field 1|3|Note"
      response = MedicaidHmisInterchange::Health::Response.new(error_report: response, submission: submission)
      response.process_response

      expect(MedicaidHmisInterchange::Health::ExternalId.count).to eq(1)
      expect(id3.reload.invalidated_at).to be_nil
      expect(response.reload.external_ids.count).to eq(0)
    end
  end

  describe 'with known ids' do
    let!(:submission) { create :mhx_submission }
    let!(:id1) { create :mhx_external_id, identifier: 'ID-1' }
    let!(:id2) { create :mhx_external_id, identifier: 'ID-2' }
    let!(:id3) { create :mhx_external_id, identifier: 'ID-3' }

    it 'only changes the flagged ids' do
      response_text = "ID_MEDICAID|RDC_HOMELESS_FLAG|FIELD|CDE_ERROR|MSG\nID-1||Field 2|2\nID-2|Y|Field 1|3|Note"
      response = MedicaidHmisInterchange::Health::Response.new(error_report: response_text, submission: submission)
      response.process_response

      expect(MedicaidHmisInterchange::Health::ExternalId.count).to eq(3)
      expect(id1.reload.invalidated_at).to be_nil
      expect(id2.reload.invalidated_at).to_not be_nil
      expect(id3.reload.invalidated_at).to be_nil

      expect(response.reload.external_ids.count).to eq(1)
    end
  end
end
