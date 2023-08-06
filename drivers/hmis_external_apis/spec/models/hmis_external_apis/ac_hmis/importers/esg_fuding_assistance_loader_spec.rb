###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::EsgFundingAssistanceLoader, type: :model do
  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:rows) do
    [
      { 'EnrollmentID' => enrollment.enrollment_id, ' PaymentStartDate' => ' 2020-01-01', ' PaymentEndDate' => ' 2020-01-01', ' FundingSource' => ' State of Pennsylvania ESG CV 2', ' PaymentType' => ' Arrears', ' Amount' => ' 100.50', ' DateCreated' => nil, ' DateUpdated' => nil, ' UserID' => nil },
    ]
  end

  it 'imports rows' do
    subject.perform(rows: rows)
    enrollment_ids = Hmis::Hud::CustomService.pluck(:enrollment_id).compact_blank
    expect(enrollment_ids.size).to eq(rows.size)
  end
end
