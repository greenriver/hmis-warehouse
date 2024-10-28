require 'rails_helper'

RSpec.describe PurgeSoftDeletedRecordsJob, type: :job do
  let(:today) { Date.current }
  let!(:data_source) { create(:hmis_data_source) }

  # Create clients with different deletion dates
  let!(:client_recent) do
    create(:hmis_hud_client, data_source: data_source, date_deleted: today - 2.month)
  end

  let!(:client_old) do
    create(:hmis_hud_client, data_source: data_source, date_deleted: today - 2.years)
  end

  let!(:client_active) do
    create(:hmis_hud_client, data_source: data_source, date_deleted: nil)
  end

  describe '#perform' do
    it 'purges only old soft-deleted records' do
      expect do
        described_class.new.perform(
          retain_at: today - 1.year,
          models: [Hmis::Hud::Client],
        )
      end.to change { Hmis::Hud::Client.with_deleted.count }.by(-1)

      # Verify the right records were affected
      expect(Hmis::Hud::Client.with_deleted.exists?(client_old.id)).to be false
      expect(Hmis::Hud::Client.with_deleted.exists?(client_recent.id)).to be true
      expect(Hmis::Hud::Client.with_deleted.exists?(client_active.id)).to be true
    end

    it 'respects the retention period parameter' do
      expect do
        described_class.new.perform(
          retain_at: today - 1.month,
          models: [Hmis::Hud::Client],
        )
      end.to change { Hmis::Hud::Client.with_deleted.count }.by(-2)

      # Both soft-deleted records should be gone
      expect(Hmis::Hud::Client.with_deleted.exists?(client_old.id)).to be false
      expect(Hmis::Hud::Client.with_deleted.exists?(client_recent.id)).to be false
      expect(Hmis::Hud::Client.with_deleted.exists?(client_active.id)).to be true
    end

    it 'raises error if non-paranoid model is passed' do
      non_paranoid_model = Class.new do
        def self.paranoid? = false
      end

      expect do
        described_class.new.perform(models: [non_paranoid_model])
      end.to raise_error('all models must be paranoid')
    end
  end
end
