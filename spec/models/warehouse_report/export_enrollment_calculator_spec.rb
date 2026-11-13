###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReport::ExportEnrollmentCalculator, type: :model do
  describe '#vispdat_for_client' do
    let(:filter) { Filters::DateRange.new(start: Date.new(2026, 9, 1), end: Date.new(2026, 9, 19)) }
    let!(:late_vispdat) { create(:vispdat, submitted_at: Time.zone.local(2026, 9, 19, 23, 59, 59)) }
    let!(:next_day_vispdat) { create(:vispdat, submitted_at: Time.zone.local(2026, 9, 20, 0, 0, 0)) }
    let(:calculator) do
      described_class.new(
        batch_scope: GrdaWarehouse::Hud::Client.where(id: [late_vispdat.client_id, next_day_vispdat.client_id]),
        filter: filter,
      )
    end

    it 'includes a VI-SPDAT submitted at the end of the last day of the range' do
      expect(calculator.vispdat_for_client(late_vispdat.client)).to eq(late_vispdat)
    end

    it 'excludes a VI-SPDAT submitted at the start of the day after the range' do
      expect(calculator.vispdat_for_client(next_day_vispdat.client)).to be_nil
    end
  end
end
