###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::WhoCharts do
  describe '.format_total' do
    it 'labels a suppressed total as 100 or fewer' do
      expect(described_class.format_total(nil, 'People')).to eq('100 or fewer People')
    end

    it 'shows zero and published totals as numbers' do
      expect([0, 101, 19_000].map { |n| described_class.format_total(n, 'People') }).to eq(['0 People', '101 People', '19,000 People'])
    end
  end

  it 'prints numbers the way JavaScript does' do
    expect([described_class.js_number(1.0), described_class.js_number(44.5), described_class.js_number(86)]).to eq(['1', '44.5', '86'])
  end

  it 'picks white text on dark fills and ink text on light fills' do
    expect([described_class.text_color('#14558F')[:color], described_class.text_color('#F6C51B')[:color]]).to eq(['#fff', '#1b1b1b'])
  end

  it 'shows an inline label only from 8% wide' do
    expect([described_class.inline_label_color(7.9, '#14558F'), described_class.inline_label_color(8, '#14558F')]).to eq([nil, '#fff'])
  end

  it 'rings fills that are under 3:1 against white' do
    expect(described_class.contrast_ring_style('#F6C51B')).to eq('box-shadow:inset 0 0 0 1px var(--color-ink);')
    expect(described_class.contrast_ring_style('#14558F')).to eq('')
  end

  it 'gives no ring and no inline label for a colour that is not six-digit hex, as charts.js does' do
    expect([described_class.contrast_ring_style('#abc'), described_class.inline_label_color(50, 'red')]).to eq(['', nil])
  end

  it 'appends the unit to a row label unless the label already ends with it' do
    expect([described_class.row_label('Sheltered', 'People'), described_class.row_label('Children-Only Households', 'Households')]).to eq(['Sheltered People', 'Children-Only Households'])
  end
end
