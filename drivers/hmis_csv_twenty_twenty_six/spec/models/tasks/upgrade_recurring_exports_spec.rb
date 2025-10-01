# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Tasks::UpgradeRecurringExports do
  describe '.upgrade!' do
    let(:user) { create(:user) }

    it 'updates version from 2024 to 2026 while preserving other options' do
      export = create(
        :recurring_hmis_export,
        user: user,
        options: {
          version: '2024',
          start_date: '2024-01-01',
          end_date: '2024-12-31',
          project_ids: [1, 2, 3],
        },
      )

      described_class.upgrade!

      export.reload
      expect(export.options['version']).to eq('2026')
      expect(export.options['start_date']).to eq('2024-01-01')
      expect(export.options['end_date']).to eq('2024-12-31')
      expect(export.options['project_ids']).to eq([1, 2, 3])
    end

    it 'does not update exports already on version 2026' do
      export = create(
        :recurring_hmis_export,
        user: user,
        options: { version: '2026' },
      )

      expect do
        described_class.upgrade!
      end.not_to(change { export.reload.updated_at })
    end

    it 'updates all 2024 exports in a batch' do
      export1 = create(:recurring_hmis_export, user: user, options: { version: '2024' })
      export2 = create(:recurring_hmis_export, user: user, options: { version: '2024' })
      export3 = create(:recurring_hmis_export, user: user, options: { version: '2026' })

      described_class.upgrade!

      expect(export1.reload.options['version']).to eq('2026')
      expect(export2.reload.options['version']).to eq('2026')
      expect(export3.reload.options['version']).to eq('2026')
    end
  end
end
