# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YouthFollowUpsJob, type: :job do
  describe '#_perform' do
    let!(:youth_follow_up_double) { class_double('GrdaWarehouse::Youth::YouthFollowUp').as_stubbed_const }

    before do
      allow(youth_follow_up_double).to receive(:recreate_follow_ups)
    end

    it 'calls to recreate follow ups' do
      described_class.new._perform
      expect(youth_follow_up_double).to have_received(:recreate_follow_ups)
    end
  end
end
