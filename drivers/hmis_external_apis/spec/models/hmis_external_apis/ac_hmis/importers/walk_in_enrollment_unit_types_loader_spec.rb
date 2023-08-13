###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::WalkInEnrollmentUnitTypesLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:unit_type_id) do
    unit_type = create(:hmis_unit_type)
    external_id = mper.create_external_id(source: unit_type, value: '22')
    create(:hmis_unit, project: enrollment.project, unit_type: unit_type)
    external_id.value
  end
  let!(:mper) do
    create(:ac_hmis_mper_credential)
    ::HmisExternalApis::AcHmis::Mper.new
  end

  let(:rows) do
    [
      {
        'PROJECTID' => enrollment.project.project_id,
        'ENROLLMENTID' => enrollment.enrollment_id,
        'UNITTYPEID' => unit_type_id,
      },
    ]
  end

  it 'imports rows' do
    with_csv_files({ 'WalkInEnrollmentUnitTypes.csv' => rows }) do |dir|
      described_class.perform(reader: csv_reader(dir))
    end
    expect(enrollment.unit_occupancies.size).to eq(1)
  end
end
