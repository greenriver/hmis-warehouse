###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
  let!(:project) { create(:hmis_hud_project, data_source: ds) }
  let!(:project_coc) { create(:hmis_hud_project_coc, data_source: ds, project: project) }
  let(:referral_id) { Hmis::Hud::Base.generate_uuid }
  let(:unit_type) do
    create(:hmis_unit_type)
  end
  let!(:unit) do
    create(:hmis_unit, project: project, unit_type: unit_type)
  end
  let!(:unit_type_id) do
    mper.create_external_id(source: unit_type, value: '22').value
  end
  let!(:mper) do
    create(:ac_hmis_mper_credential)
    ::HmisExternalApis::AcHmis::Mper.new
  end
  let!(:walkin_cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Project', key: :direct_entry, field_type: :boolean, data_source: ds) }

  # we expect the bogus referral to be skipped
  let(:bogus_referral_id) { 'bogus_referral' }

  let(:base_posting_row) do
    {
      'REFERRAL_ID' => referral_id,
      'REFERRAL_DATE' => '2022-12-01 14:00:00',
      'SERVICE_COORDINATOR' => 'test1',
      'REFERRAL_NOTES' => 'base referral',
      'CHRONIC' => 'No',
      'SCORE' => '2',
      'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT' => 'No',
      'POSTING_ID' => Hmis::Hud::Base.generate_uuid,
      'PROGRAM_ID' => project.project_id,
      'UNIT_TYPE_ID' => unit_type_id,
      'ASSIGNED_AT' => '2022-12-01 14:00:00',
      'STATUS_UPDATED_AT' => '2022-12-01 14:00:00',
      'RESOURCE_COORDINATOR_NOTES' => '',
    }
  end
  let(:bogus_posting_row) do
    {
      'REFERRAL_ID' => bogus_referral_id,
      'REFERRAL_DATE' => '2022-12-01 14:00:00',
      'SERVICE_COORDINATOR' => 'test1',
      'REFERRAL_NOTES' => 'bogus referral',
      'CHRONIC' => 'No',
      'SCORE' => '2',
      'NEEDS_WHEELCHAIR_ACCESSIBLE_UNIT' => 'No',
      'POSTING_ID' => Hmis::Hud::Base.generate_uuid,
      'PROGRAM_ID' => project.project_id,
      'UNIT_TYPE_ID' => unit_type_id,
      'ASSIGNED_AT' => '2022-12-01 14:00:00',
      'STATUS_UPDATED_AT' => '2022-12-01 14:00:00',
      'RESOURCE_COORDINATOR_NOTES' => '',
    }
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
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:enrollment) { create(:hmis_hud_enrollment, personal_id: client.personal_id, data_source: ds, project: project, household_id: household_id) }
    let(:other_enrollment) { create(:hmis_hud_enrollment, personal_id: other_client.personal_id, data_source: ds, project: project, household_id: household_id) }
    let(:posting_rows) do
      [
        base_posting_row.merge('STATUS' => 'Accepted', 'ENROLLMENTID' => enrollment.enrollment_id),
        base_posting_row.merge('STATUS' => 'Accepted', 'ENROLLMENTID' => other_enrollment.enrollment_id),
        bogus_posting_row.merge('STATUS' => 'Accepted'),
      ]
    end

    it 'creates referral records, unit occupancy, but not enrollment' do
      csv_files = {
        'ReferralPostings.csv' => posting_rows,
        'ReferralHouseholdMembers.csv' => household_member_rows,
      }
      expect do
        run_cde_import(csv_files: csv_files, clobber: true)
      end.to change(HmisExternalApis::AcHmis::Referral, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralPosting, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralHouseholdMember, :count).by(2).
        and change(enrollment.unit_occupancies, :count).by(1).
        and change(other_enrollment.unit_occupancies, :count).by(1).
        and not_change(Hmis::Hud::Enrollment, :count)
      expect(Hmis::UnitOccupancy.distinct.pluck(:unit_id)).to eq([unit.id])
    end
  end

  describe 'for assigned referrals' do
    let(:posting_rows) do
      [
        base_posting_row.merge('STATUS' => 'Assigned'),
        base_posting_row.merge('STATUS' => 'Assigned'),
        bogus_posting_row.merge('STATUS' => 'Assigned'),
      ]
    end
    let!(:walkin_flag) { create(:hmis_custom_data_element, owner: project, data_element_definition: walkin_cded, value_boolean: false, data_source: ds) }

    it 'creates referral records, but not enrollment or unit occupancy' do
      csv_files = {
        'ReferralPostings.csv' => posting_rows,
        'ReferralHouseholdMembers.csv' => household_member_rows,
      }
      expect do
        run_cde_import(csv_files: csv_files, clobber: true)
      end.to change(HmisExternalApis::AcHmis::Referral, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralPosting, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralHouseholdMember, :count).by(2).
        and not_change(Hmis::Hud::Enrollment, :count).
        and not_change(Hmis::UnitOccupancy, :count)
    end

    it 'does create enrollment and unit occupancy IF project accepts walk-in' do
      walkin_flag.update(value_boolean: true)
      csv_files = {
        'ReferralPostings.csv' => posting_rows,
        'ReferralHouseholdMembers.csv' => household_member_rows,
      }
      expect do
        run_cde_import(csv_files: csv_files, clobber: true)
      end.to change(HmisExternalApis::AcHmis::Referral, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralPosting, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralHouseholdMember, :count).by(2).
        and change(Hmis::Hud::Enrollment, :count).by(2).
        and change(Hmis::Hud::Enrollment.in_progress, :count).by(2).
        and change(Hmis::UnitOccupancy, :count).by(2)
      expect(Hmis::UnitOccupancy.distinct.pluck(:unit_id)).to eq([unit.id])
    end
  end

  describe 'for accepted pending referrals' do
    let(:posting_rows) do
      [
        base_posting_row.merge('STATUS' => 'Accepted Pending'),
        bogus_posting_row.merge('STATUS' => 'Accepted Pending'),
      ]
    end

    it 'creates referral records, enrollment, and unit occupancy' do
      csv_files = {
        'ReferralPostings.csv' => posting_rows,
        'ReferralHouseholdMembers.csv' => household_member_rows,
      }
      expect do
        run_cde_import(csv_files: csv_files, clobber: true)
      end.to change(HmisExternalApis::AcHmis::Referral, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralPosting, :count).by(1).
        and change(HmisExternalApis::AcHmis::ReferralHouseholdMember, :count).by(2).
        and change(Hmis::Hud::Enrollment, :count).by(2).
        and change(Hmis::Hud::Enrollment.in_progress, :count).by(2).
        and change(Hmis::UnitOccupancy, :count).by(2)

      expect(Hmis::UnitOccupancy.distinct.pluck(:unit_id)).to eq([unit.id])
    end
  end

  describe 'with no hoh' do
    let(:household_member_rows) do
      [
        {
          'REFERRAL_ID' => referral_id,
          'MCI_ID' => mci_id.value,
          'RELATIONSHIP_TO_HOH_ID' => '99', # non hoh
        },
      ]
    end
    let(:posting_rows) do
      [base_posting_row.merge('STATUS' => 'Accepted Pending')]
    end
    it 'chooses a hoh' do
      csv_files = {
        'ReferralPostings.csv' => posting_rows,
        'ReferralHouseholdMembers.csv' => household_member_rows,
      }
      expect do
        run_cde_import(csv_files: csv_files, clobber: true)
      end.to change(HmisExternalApis::AcHmis::ReferralHouseholdMember.where(relationship_to_hoh: 'self_head_of_household'), :count).by(1)
    end
  end
end
