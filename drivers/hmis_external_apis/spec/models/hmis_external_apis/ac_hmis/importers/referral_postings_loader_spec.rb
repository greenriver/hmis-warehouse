###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::ReferralPostingsLoader, type: :model do
  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds) }
  let(:referral_id) { Hmis::Hud::Base.generate_uuid }
  let!(:mper) do
    create(:ac_hmis_mper_credential)
    ::HmisExternalApis::AcHmis::Mper.new
  end
  let(:unit_type_id) do
    record = mper.create_external_id(source: create(:hmis_unit_type), value: '22')
    record.value
  end

  let(:posting_rows) do
    [
      {
        'REFERRAL_ID' => referral_id,
        'REFERRAL_DATE' => '18-MAY-23',
        'SERVICE_COORDINATOR' => 'test1',
        'REFERRAL_NOTES' => 'test2',
        'CHRONIC' => 'No',
        'SCORE' => '2',
        'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT' => 'No',
        'POSTING_ID' => Hmis::Hud::Base.generate_uuid,
        'STATUS' => 'Assigned',
        'PROGRAM_ID' => enrollment.project_id,
        'UNIT_TYPE_ID' => unit_type_id,
        'ASSIGNED_AT' => '07-DEC-22',
        'STATUS_UPDATED_AT' => '07-DEC-22',
        'RESOURCE_COORDINATOR_NOTES' => '',
        # 'STATUS_NOTE/DENIAL_NOTE'=> '',
        # 'DENIAL_REASON'=> '',
        # 'REFERRAL_RESULT'=> '',
      },
    ]
  end

  let(:household_member_rows) do
    [
      {
        'REFERRAL_ID' => referral_id,
        'MCI_ID' => enrollment.personal_id,
        'RELATIONSHIP_TO_HOH' => 'Self',
      },
    ]
  end

  it 'imports rows' do
    subject.perform(
      posting_rows: posting_rows,
      household_member_rows: household_member_rows,
    )
    expect(enrollment.external_referrals.size).to eq(1)
  end
end
