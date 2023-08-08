###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::WalkInEnrollmentUnitTypesLoader, type: :model do
  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:rows) do
    [
      {
        'PROJECTID' => enrollment.project.project_id,
        'ENROLLMENTID' => enrollment.enrollment_id,
        'UNITTYPEID' => '12/08/2021',
      }
    ]
  end

  it 'imports rows' do
    subject.perform(rows: rows)
    expect(enrollment.unit_occupancies.size).to eq(1)
  end
end
