###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeSoftDeletedRecordsJob, type: :job do
  let(:today) { Date.current }
  let!(:data_source) { create(:grda_warehouse_data_source) }

  # Create clients with different deletion dates
  let!(:client_recent) do
    create(:grda_warehouse_hud_client, data_source: data_source, date_deleted: today - 2.month)
  end

  let!(:client_old) do
    create(:grda_warehouse_hud_client, data_source: data_source, date_deleted: today - 2.years)
  end

  let!(:client_active) do
    create(:grda_warehouse_hud_client, data_source: data_source, date_deleted: nil)
  end

  # Create dependent records
  let!(:warehouse_client_old) do
    create(:warehouse_client, source: client_old)
  end

  let!(:warehouse_client_recent) do
    create(:warehouse_client, source: client_recent)
  end

  let!(:warehouse_client_active) do
    create(:warehouse_client, source: client_active)
  end

  let!(:referral_member_old) do
    record = build(:hmis_external_api_ac_hmis_referral_household_member, client_id: client_old.id)
    record.save(validate: false)
    record
  end

  let!(:referral_member_recent) do
    record = build(:hmis_external_api_ac_hmis_referral_household_member, client_id: client_recent.id)
    record.save(validate: false)
    record
  end

  let!(:referral_member_active) do
    create(:hmis_external_api_ac_hmis_referral_household_member, client_id: client_active.id)
  end

  before do
    AppConfigProperty.create!(key: 'purge_soft_deleted_records/enabled', value: '1')
  end

  describe '#perform' do
    it 'purges only old soft-deleted records' do
      expect do
        described_class.new.perform(
          retain_at: today - 1.year,
          models: [GrdaWarehouse::Hud::Client],
          dry_run: false,
        )
      end.to change { GrdaWarehouse::Hud::Client.with_deleted.count }.by(-1)

      # Verify dependent records for old client were removed
      expect(GrdaWarehouse::WarehouseClient.exists?(warehouse_client_old.id)).to be false
      expect(HmisExternalApis::AcHmis::ReferralHouseholdMember.exists?(referral_member_old.id)).to be false

      # Verify dependent records for recent and active clients were not removed
      expect(GrdaWarehouse::WarehouseClient.exists?(warehouse_client_recent.id)).to be true
      expect(GrdaWarehouse::WarehouseClient.exists?(warehouse_client_active.id)).to be true
      expect(HmisExternalApis::AcHmis::ReferralHouseholdMember.exists?(referral_member_recent.id)).to be true
      expect(HmisExternalApis::AcHmis::ReferralHouseholdMember.exists?(referral_member_active.id)).to be true
    end
  end

  describe '#perform on enrollments referenced by a CE referral' do
    let!(:ce_referral) { create(:hmis_ce_referral) }

    # the target enrollment must be in the referral's project, the source enrollment need not be
    let!(:target_enrollment) do
      create(
        :hmis_hud_enrollment,
        data_source: ce_referral.data_source,
        project: ce_referral.target_project,
        date_deleted: today - 2.years,
      )
    end
    let!(:source_enrollment) do
      create(:hmis_hud_enrollment, data_source: ce_referral.data_source, date_deleted: today - 2.years)
    end
    let!(:unreferenced_enrollment) do
      create(:hmis_hud_enrollment, data_source: ce_referral.data_source, date_deleted: today - 2.years)
    end

    # a referral that holds neither foreign key must not prevent unreferenced enrollments from being purged
    let!(:referral_without_enrollments) { create(:hmis_ce_referral) }

    # a soft-deleted referral still holds the foreign keys
    let(:referral_soft_deleted) { false }

    before do
      ce_referral.update!(target_enrollment: target_enrollment, source_enrollment: source_enrollment)
      ce_referral.destroy! if referral_soft_deleted
    end

    def run_purge
      described_class.new.perform(
        retain_at: today - 1.year,
        models: [GrdaWarehouse::Hud::Enrollment],
        dry_run: false,
      )
    end

    it 'skips referenced enrollments and purges the rest' do
      expect(referral_without_enrollments.target_enrollment_id).to be_nil
      expect(referral_without_enrollments.source_enrollment_id).to be_nil

      run_purge

      with_deleted = GrdaWarehouse::Hud::Enrollment.with_deleted
      expect(with_deleted.exists?(target_enrollment.id)).to be true
      expect(with_deleted.exists?(source_enrollment.id)).to be true
      expect(with_deleted.exists?(unreferenced_enrollment.id)).to be false
    end

    context 'when the referral is soft-deleted' do
      let(:referral_soft_deleted) { true }

      it 'still skips referenced enrollments' do
        run_purge

        with_deleted = GrdaWarehouse::Hud::Enrollment.with_deleted
        expect(with_deleted.exists?(target_enrollment.id)).to be true
        expect(with_deleted.exists?(source_enrollment.id)).to be true
      end
    end
  end
end
