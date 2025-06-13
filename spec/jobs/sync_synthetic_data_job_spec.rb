# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncSyntheticDataJob, type: :job do
  describe '#_perform' do
    let!(:non_hmis_client_double) { class_double('CasAccess::NonHmisClient').as_stubbed_const }
    let!(:assessment_double) { class_double('GrdaWarehouse::Synthetic::Assessment').as_stubbed_const }
    let!(:event_double) { class_double('GrdaWarehouse::Synthetic::Event').as_stubbed_const }
    let!(:youth_education_double) { class_double('GrdaWarehouse::Synthetic::YouthEducationStatus').as_stubbed_const }

    before do
      allow(CasBase).to receive(:db_exists?).and_return(true)
      allow(non_hmis_client_double).to receive(:find_exact_matches)
      allow(assessment_double).to receive(:hud_sync)
      allow(event_double).to receive(:hud_sync)
      allow(youth_education_double).to receive(:hud_sync)
    end

    it 'calls all the sync methods' do
      described_class.new.perform

      expect(non_hmis_client_double).to have_received(:find_exact_matches)
      expect(assessment_double).to have_received(:hud_sync)
      expect(event_double).to have_received(:hud_sync)
      expect(youth_education_double).to have_received(:hud_sync)
    end

    context 'when cas db does not exist' do
      it 'does not run' do
        allow(CasBase).to receive(:db_exists?).and_return(false)
        described_class.new.perform
        expect(non_hmis_client_double).not_to have_received(:find_exact_matches)
      end
    end
  end
end
