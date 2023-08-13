###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::EsgFundingAssistanceLoader, type: :model do
  include AcHmisLoaderHelpers
  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:rows) do
    [
      {
        'ENROLLMENTID' => enrollment.enrollment_id,
        'PAYMENTSTARTDATE' => '2022-12-01 14:00:00 ',
        'PAYMENTENDDATE' => '2022-12-01 14:00:00',
        'FUNDINGSOURCE' => 'State of Pennsylvania ESG CV 2',
        'PAYMENTTYPE' => 'Arrears',
        'AMOUNT' => ' 100.50',
        'DATECREATED' => '2022-12-01 14:00:00',
        'DATEUPDATED' => '2022-12-01 14:00:00',
        'USERID' => nil,
      },
    ]
  end

  it 'imports rows' do
    with_csv_files({ 'ESGFundingAssistance.csv' => rows }) do |dir|
      described_class.perform(reader: csv_reader(dir))
    end
    expect(enrollment.custom_services.size).to eq(1)
    expect(enrollment.custom_services.first.custom_data_elements.size).to eq(2)
  end
end
