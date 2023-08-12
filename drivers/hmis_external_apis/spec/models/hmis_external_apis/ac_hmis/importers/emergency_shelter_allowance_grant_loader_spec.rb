###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::EmergencyShelterAllowanceGrantLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:rows) do
    [
      {
        'ENROLLMENTID' => enrollment.enrollment_id,
        'REFERREDTOALLOWANCEGRANT' => '1',
        'RECEVIEDFUNDING' => '2',
        'AMOUNTRECEIVED' => '100.50',
        'REASONNOTREFERRED' => '602',
      }
    ]
  end

  it 'imports rows' do
    with_csv_files({ 'EmergencyShelterAllowanceGrant.csv' => rows }) do |dir|
      described_class.perform(reader: csv_reader(dir))
    end
    expect(enrollment.custom_data_elements.size).to eq(4) # each col is a CDE
  end
end
