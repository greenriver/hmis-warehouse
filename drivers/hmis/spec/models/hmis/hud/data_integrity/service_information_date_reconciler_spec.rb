# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

# a simple test to make sure this is wired up correctly
RSpec.describe Hmis::Hud::DataIntegrity::ServiceInformationDateReconciler, type: :model do
  let(:start_date) { Date.new(2025, 1, 1) }

  describe '.call' do
    context 'for non-SSVF Financial Assistance services' do
      # just use a record_type that is not SSVF FA
      let(:service) { build(:hmis_hud_service, record_type: 1, fa_start_date: start_date, information_date: nil) }

      it 'sets the service_information_date from fa_start_date' do
        messages = described_class.call(service)

        expect(service.information_date).to eq(start_date)
        expect(messages).to be_empty
      end

      it 'generates a message if the date cannot be set' do
        service.fa_start_date = nil
        messages = described_class.call(service)

        expect(service.information_date).to be_nil
        expect(messages.first).to match(/information_date should be present/)
      end
    end

    context 'for SSVF Financial Assistance services' do
      let(:record_type) { HudUtility2026.record_type('SSVF Financial Assistance', true, raise_on_missing: true) }
      let(:service) do
        build(:hmis_hud_service, record_type: record_type, fa_start_date: start_date, information_date: nil)
      end

      it 'does not set service_information_date and reports that it is missing' do
        messages = described_class.call(service)

        expect(service.information_date).to be_nil
        expect(messages.first).to match(/information_date should be present/)
      end

      it 'does not generate a message if information_date is already present' do
        service.information_date = start_date
        messages = described_class.call(service)
        expect(messages).to be_empty
      end
    end
  end
end
