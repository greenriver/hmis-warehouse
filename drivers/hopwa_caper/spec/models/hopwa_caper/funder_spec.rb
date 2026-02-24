# frozen_string_literal: true

require 'rails_helper'
require_relative '../generators/fy2026/hopwa_caper_shared_context'

RSpec.describe HopwaCaper::Funder, type: :model do
  include_context 'HOPWA CAPER shared context'

  describe 'within_range scope and within_range? method' do
    let(:php_funder) do
      HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing Placement')
    end
    let(:report_start) { Date.new(2026, 1, 1) }
    let(:report_end) { Date.new(2026, 12, 31) }
    let(:range) { report_start..report_end }

    describe '.within_range' do
      it 'includes funding that overlaps the range' do
        funder = create(:hopwa_caper_funder, code: php_funder, start_date: report_start - 1.month, end_date: report_start + 1.month)
        expect(HopwaCaper::Funder.within_range(range)).to include(funder)
      end

      it 'includes open-ended funding that started before the range' do
        funder = create(:hopwa_caper_funder, code: php_funder, start_date: report_start - 1.year, end_date: nil)
        expect(HopwaCaper::Funder.within_range(range)).to include(funder)
      end

      it 'excludes funding that ended before the range' do
        funder = create(:hopwa_caper_funder, code: php_funder, start_date: report_start - 1.year, end_date: report_start - 1.day)
        expect(HopwaCaper::Funder.within_range(range)).not_to include(funder)
      end

      it 'excludes funding that starts after the range' do
        funder = create(:hopwa_caper_funder, code: php_funder, start_date: report_end + 1.day, end_date: report_end + 1.year)
        expect(HopwaCaper::Funder.within_range(range)).not_to include(funder)
      end
    end

    describe '#within_range?' do
      it 'returns true if funding overlaps the range' do
        funder = build(:hopwa_caper_funder, start_date: report_start - 1.month, end_date: report_start + 1.month)
        expect(funder.within_range?(range)).to be true
      end

      it 'returns false if funding does not overlap the range' do
        funder = build(:hopwa_caper_funder, start_date: report_start - 1.year, end_date: report_start - 1.day)
        expect(funder.within_range?(range)).to be false
      end
    end
  end
end
