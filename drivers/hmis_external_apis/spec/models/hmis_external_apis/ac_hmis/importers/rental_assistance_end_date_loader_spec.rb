###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::RentalAssistanceEndDateLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:rows) do
    [
      {
        'ENROLLMENTID' => enrollment.enrollment_id,
        'RENTALASSISTANCEENDDATE' => '2022-12-01 14:00:00',
      },
    ]
  end

  it 'imports rows' do
    csv_files = { 'RentalAssistanceEndDate.csv' => rows }
    expect do
      run_cde_import(csv_files: csv_files, clobber: true)
    end.to change(enrollment.custom_data_elements, :count).by(1)
  end
end
