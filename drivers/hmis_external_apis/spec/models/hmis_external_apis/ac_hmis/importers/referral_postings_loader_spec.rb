###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::ReferralPostingsLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:mci_cred) do
    create(:ac_hmis_mci_credential)
  end
  let(:mci_id) do
    create :mci_external_id, source: client, remote_credential: mci_cred
  end
  let(:other_mci_id) do
    create :mci_external_id, source: other_client, remote_credential: mci_cred
  end
  let!(:client) { create(:hmis_hud_client, data_source: ds) }
  let!(:other_client) { create(:hmis_hud_client, data_source: ds) }
  let(:project) { create(:hmis_hud_project, data_source: ds) }
  let(:referral_id) { Hmis::Hud::Base.generate_uuid }
  let(:unit_type) {
    create(:hmis_unit_type)
  }
  let!(:unit) {
    create(:hmis_unit, project: project, unit_type: unit_type)
  }
  let!(:unit_type_id) do
    mper.create_external_id(source: unit_type, value: '22').value
  end
  let!(:mper) do
    create(:ac_hmis_mper_credential)
    ::HmisExternalApis::AcHmis::Mper.new
  end
  # we expect the bogus referral to be skipped
  let(:bogus_referral_id) { 'bogus_referral' }

  let(:base_posting_rows) do
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
        'PROGRAM_ID' => project.project_id,
        'UNIT_TYPE_ID' => unit_type_id,
        'ASSIGNED_AT' => '2022-12-01 14:00:00',
        'STATUS_UPDATED_AT' => '2022-12-01 14:00:00',
        'RESOURCE_COORDINATOR_NOTES' => '',
      },
      {
        'REFERRAL_ID' => bogus_referral_id,
        'REFERRAL_DATE' => '2022-12-01 14:00:00',
        'SERVICE_COORDINATOR' => 'test1',
        'REFERRAL_NOTES' => 'test2',
        'CHRONIC' => 'No',
        'SCORE' => '2',
        'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT' => 'No',
        'POSTING_ID' => Hmis::Hud::Base.generate_uuid,
        'PROGRAM_ID' => project.project_id,
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
        'MCI_ID' => mci_id.value,
        'RELATIONSHIP_TO_HOH_ID' => '1',
      },
      {
        'REFERRAL_ID' => referral_id,
        'MCI_ID' => other_mci_id.value,
        'RELATIONSHIP_TO_HOH_ID' => '4',
      },
      {
        'REFERRAL_ID' => bogus_referral_id,
        'MCI_ID' => 'bogus_mci',
        'RELATIONSHIP_TO_HOH_ID' => '1',
      },
    ]
  end

  describe 'for an accepted referral' do
    let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds, project: project) }
    let(:posting_rows) do
      base_posting_rows.each do |row|
        row['STATUS'] = 'Accepted'
        row['ENROLLMENTID'] = enrollment.enrollment_id if row['REFERRAL_ID'] == referral_id
      end
    end

    it 'creates referral records, unit occupancy, but not enrollment' do
      create(:hmis_hud_enrollment, personal_id: other_client.personal_id, data_source: ds, project: project)

      csv_files = {
        'ReferralPostings.csv' => posting_rows,
        'ReferralHouseholdMembers.csv' => household_member_rows,
      }
      expect do
        run_cde_import(csv_files: csv_files, clobber: true)
      end.to change(HmisExternalApis::AcHmis::Referral, :count).by(1)
        .and change(HmisExternalApis::AcHmis::ReferralPosting, :count).by(1)
        .and change(HmisExternalApis::AcHmis::ReferralHouseholdMember, :count).by(2)
        .and change(enrollment.unit_occupancies, :count).by(1)
        .and not_change(Hmis::Hud::Enrollment, :count)
      expect(Hmis::UnitOccupancy.distinct.pluck(:unit_id)).to eq([unit.id])
    end
  end

  describe 'with accepted pending referral' do
    let(:posting_rows) do
      base_posting_rows.each { |r| r['STATUS'] = 'Accepted Pending' }
    end

    it 'creates referral records, enrollment, and unit occupancy' do
      csv_files = {
        'ReferralPostings.csv' => posting_rows,
        'ReferralHouseholdMembers.csv' => household_member_rows,
      }
      expect do
        run_cde_import(csv_files: csv_files, clobber: true)
      end.to change(HmisExternalApis::AcHmis::Referral, :count).by(1)
        .and change(HmisExternalApis::AcHmis::ReferralPosting, :count).by(1)
        .and change(HmisExternalApis::AcHmis::ReferralHouseholdMember, :count).by(2)
        .and change(Hmis::Wip, :count).by(2)
        .and change(Hmis::Hud::Enrollment, :count).by(2)
        .and change(Hmis::UnitOccupancy, :count).by(2)

      expect(Hmis::UnitOccupancy.distinct.pluck(:unit_id)).to eq([unit.id])
    end
  end
end
