###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::ReferralRequestsLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:project) { create :hmis_hud_project, data_source: ds }
  let(:referral_request_id) { Hmis::Hud::Base.generate_uuid }
  let!(:mper) do
    create(:ac_hmis_mper_credential)
    ::HmisExternalApis::AcHmis::Mper.new
  end
  let(:unit_type_id) do
    record = mper.create_external_id(source: create(:hmis_unit_type), value: '22')
    record.value
  end
  let(:rows) do
    [
      {
        'REFERRAL_REQUEST_ID' => referral_request_id,
        'PROGRAM_ID' => project.project_id,
        'UNIT_TYPE_ID' => unit_type_id,
        'REQUESTED_ON' => '2022-12-01 14:00:00',
        'NEEDED_BY' => '2022-12-01 14:00:00',
        'REQUESTOR_NAME' => 'test name',
        'REQUESTOR_PHONE' => 'test phone',
        'REQUESTOR_EMAIL' => 'test email',
      },
    ]
  end

  it 'imports rows' do
    csv_files = { 'ReferralRequests.csv' => rows }
    expect do
      run_cde_import(csv_files: csv_files, clobber: true)
    end.to change(project.external_referral_requests, :count).by(1)

    expect do
      run_cde_import(csv_files: csv_files, clobber: false)
    end.not_to change(project.external_referral_requests, :count)
  end
end
