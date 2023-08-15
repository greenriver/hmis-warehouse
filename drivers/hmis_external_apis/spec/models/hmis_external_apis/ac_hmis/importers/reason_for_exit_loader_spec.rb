###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::ReasonForExitLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:exit) { create(:hmis_hud_exit, data_source: ds, enrollment: enrollment, client: client) }
  let(:rows) do
    [
      {
        'ExitID' => exit.exit_id,
        'EnrollmentID' => enrollment.enrollment_id,
        'ReasonForExit' => 'Other',
        'ReasonForExitOther' => 'test',
        'VoluntaryTermination' => 'Y',
      },
    ]
  end

  it 'imports rows' do
    csv_files = { 'ReasonForExit.csv' => rows }
    expect do
      run_cde_import(csv_files: csv_files, clobber: true)
    end.to change(exit.custom_data_elements, :count).by(3)
  end
end
