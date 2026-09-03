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

  describe '#perform on enrollments' do
    let!(:ce_referral) { create(:hmis_ce_referral) }
    let!(:referral_note) { create(:hmis_ce_referral_note, referral: ce_referral) }
    let!(:referral_participant) { create(:hmis_ce_referral_participant, referral: ce_referral) }

    # the target enrollment must be in the referral's project, the source enrollment need not be
    let(:target_enrollment) do
      create(
        :hmis_hud_enrollment,
        data_source: ce_referral.data_source,
        project: ce_referral.target_project,
        date_deleted: target_date_deleted,
      )
    end
    let(:source_enrollment) do
      create(:hmis_hud_enrollment, data_source: ce_referral.data_source, date_deleted: source_date_deleted)
    end

    let(:old) { today - 2.years }
    let(:recent) { today - 2.months }

    # Enrollment declares dependent: :destroy only on the source side (has_many :outgoing_ce_referrals), so a
    # referral pointing at a soft-deleted enrollment is frequently still live itself
    let(:referral_soft_deleted) { true }

    before do
      ce_referral.update!(target_enrollment: target_enrollment, source_enrollment: source_enrollment)
      # a soft-deleted referral still holds the foreign key
      ce_referral.destroy! if referral_soft_deleted
    end

    def run_purge
      described_class.new.perform(
        retain_at: today - 1.year,
        models: [GrdaWarehouse::Hud::Enrollment],
        dry_run: false,
      )
    end

    context 'when both enrollments are purged' do
      let(:target_date_deleted) { old }
      let(:source_date_deleted) { old }

      it 'clears both references and leaves the referral to its own retention date' do
        expect { run_purge }.to change { GrdaWarehouse::Hud::Enrollment.with_deleted.count }.by(-2)

        expect(Hmis::Ce::Referral.with_deleted.exists?(ce_referral.id)).to be true
        ce_referral.reload
        expect(ce_referral.target_enrollment_id).to be_nil
        expect(ce_referral.source_enrollment_id).to be_nil
      end
    end

    context 'when only the target enrollment is purged' do
      let(:target_date_deleted) { old }
      let(:source_date_deleted) { recent }

      it 'keeps the referral and clears target_enrollment_id' do
        expect { run_purge }.to change { GrdaWarehouse::Hud::Enrollment.with_deleted.count }.by(-1)

        expect(GrdaWarehouse::Hud::Enrollment.with_deleted.exists?(source_enrollment.id)).to be true

        ce_referral.reload
        expect(ce_referral.target_enrollment_id).to be_nil
        expect(ce_referral.source_enrollment_id).to eq(source_enrollment.id)
      end
    end

    context 'when the referral is live and its target enrollment is purged' do
      let(:referral_soft_deleted) { false }
      let(:target_date_deleted) { old }
      let(:source_date_deleted) { recent }

      it 'keeps the referral and clears target_enrollment_id' do
        expect { run_purge }.to change { GrdaWarehouse::Hud::Enrollment.with_deleted.count }.by(-1)

        ce_referral.reload
        expect(ce_referral.deleted_at).to be_nil
        expect(ce_referral.target_enrollment_id).to be_nil
      end
    end

    context 'when the referral is itself soft-deleted past the retention date' do
      let(:target_date_deleted) { old }
      let(:source_date_deleted) { old }

      before do
        ce_referral.update_column(:deleted_at, old)
        [referral_note, referral_participant].each { |record| record.update_column(:deleted_at, old) }
      end

      # run the real model list so its ordering (dependents before referral) is covered too
      it 'purges the referral and its dependents' do
        described_class.new.perform(retain_at: today - 1.year, dry_run: false)

        expect(Hmis::Ce::Referral.with_deleted.exists?(ce_referral.id)).to be false
        expect(Hmis::Ce::ReferralNote.with_deleted.exists?(referral_note.id)).to be false
        expect(Hmis::Ce::ReferralParticipant.with_deleted.exists?(referral_participant.id)).to be false
        expect(GrdaWarehouse::Hud::Enrollment.with_deleted.exists?(target_enrollment.id)).to be false
      end
    end

    context 'when only the source enrollment is purged' do
      let(:target_date_deleted) { recent }
      let(:source_date_deleted) { old }

      it 'keeps the referral and clears source_enrollment_id' do
        expect { run_purge }.to change { GrdaWarehouse::Hud::Enrollment.with_deleted.count }.by(-1)

        expect(GrdaWarehouse::Hud::Enrollment.with_deleted.exists?(target_enrollment.id)).to be true

        ce_referral.reload
        expect(ce_referral.source_enrollment_id).to be_nil
        expect(ce_referral.target_enrollment_id).to eq(target_enrollment.id)
      end
    end

    context 'when neither enrollment is purged' do
      let(:target_date_deleted) { recent }
      let(:source_date_deleted) { recent }

      it 'leaves the referral untouched' do
        expect { run_purge }.not_to(change { GrdaWarehouse::Hud::Enrollment.with_deleted.count })

        ce_referral.reload
        expect(ce_referral.target_enrollment_id).to eq(target_enrollment.id)
        expect(ce_referral.source_enrollment_id).to eq(source_enrollment.id)
      end
    end

    context 'on a dry run' do
      let(:target_date_deleted) { old }
      let(:source_date_deleted) { recent }

      it 'does not clear the reference' do
        described_class.new.perform(
          retain_at: today - 1.year,
          models: [GrdaWarehouse::Hud::Enrollment],
          dry_run: true,
        )

        expect(GrdaWarehouse::Hud::Enrollment.with_deleted.exists?(target_enrollment.id)).to be true
        ce_referral.reload
        expect(ce_referral.target_enrollment_id).to eq(target_enrollment.id)
      end
    end
  end
end
