###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::ReferralPostingsLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let!(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:referral_id) { Hmis::Hud::Base.generate_uuid }
  let!(:unit_type_id) do
    unit_type = create(:hmis_unit_type)
    external_id = mper.create_external_id(source: unit_type, value: '22')
    create(:hmis_unit, project: enrollment.project, unit_type: unit_type)
    external_id.value
  end
  let!(:mper) do
    create(:ac_hmis_mper_credential)
    ::HmisExternalApis::AcHmis::Mper.new
  end

  let(:posting_rows) do
    [
      {
        'REFERRAL_ID' => referral_id,
        'REFERRAL_DATE' => '2022-12-01 14:00:00',
        'SERVICE_COORDINATOR' => 'test1',
        'REFERRAL_NOTES' => 'test2',
        'CHRONIC' => 'No',
        'SCORE' => '2',
        'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT' => 'No',
        'POSTING_ID' => Hmis::Hud::Base.generate_uuid,
        'STATUS' => 'Accepted Pending',
        'PROGRAM_ID' => enrollment.project_id,
        'UNIT_TYPE_ID' => unit_type_id,
        'ASSIGNED_AT' => '2022-12-01 14:00:00',
        'STATUS_UPDATED_AT' => '2022-12-01 14:00:00',
        'RESOURCE_COORDINATOR_NOTES' => '',
      },
    ]
  end

  let(:household_member_rows) do
    [
      {
        'REFERRAL_ID' => referral_id,
        'MCI_ID' => enrollment.personal_id,
        'RELATIONSHIP_TO_HOH' => '1',
      },
    ]
  end

  it 'imports rows' do
    csv_files = {
      'ReferralPostings.csv' => posting_rows,
      'ReferralHouseholdMembers.csv' => household_member_rows,
    }
    expect do
      run_cde_import(csv_files: csv_files, clobber: true)
    end.to change(enrollment.external_referrals, :count).by(1)
      .and change(enrollment.unit_occupancies, :count).by(1)

    expect(enrollment.external_referrals.first.postings.size).to eq(1)
    expect(enrollment.external_referrals.first.household_members.size).to eq(1)
    expect(enrollment.unit_occupancies.size).to eq(1)
  end
end
