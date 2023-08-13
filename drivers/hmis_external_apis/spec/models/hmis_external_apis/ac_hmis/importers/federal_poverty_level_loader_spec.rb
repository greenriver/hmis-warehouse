###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::FederalPovertyLevelLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:income_benefits) { create(:hmis_income_benefit, data_source: ds, client: client, enrollment: enrollment) }

  let(:rows) do
    [
      {
        'ENROLLMENTID' => enrollment.enrollment_id,
        'INCOMEBENEFITSID' => income_benefits.income_benefits_id,
        'FEDERALPOVERTYLEVEL' => '100',
      },
    ]
  end

  it 'imports rows' do
    with_csv_files({ 'FederalPovertyLevel.csv' => rows }) do |dir|
      described_class.perform(reader: csv_reader(dir))
    end
    expect(income_benefits.custom_data_elements.size).to eq(1) # each col is a CDE
  end
end
