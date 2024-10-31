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
end
