###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard::DonutChart do
  let(:arcs) do
    described_class.new([{ label: 'Sheltered', value: 86, color: '#14558F' }, { label: 'Unsheltered', value: 14, color: '#3E94CF' }]).arcs
  end

  it 'turns each percentage into a dash pattern starting at 12 o’clock' do
    expect(arcs.map(&:dasharray)).to eq(['86 14', '14 86'])
    expect(arcs.map(&:dashoffset)).to eq(['25', '-61'])
  end

  it 'draws a divider at the start of each segment' do
    expect(arcs.first.divider).to eq(x1: '21.00', y1: '9.08', x2: '21.00', y2: '1.08')
  end

  it 'anchors each tooltip by where its segment midpoint falls' do
    expect(arcs.map { |a| a.tooltip[:anchor] }).to eq(['middle', 'end'])
    expect(arcs.first.tooltip[:width]).to eq('32.40')
  end

  it 'draws no divider for a single full segment' do
    arc = described_class.new([{ label: 'All', value: 100, color: '#14558F' }]).arcs.first
    expect([arc.divider, arc.dasharray]).to eq([nil, '100 0'])
  end

  it 'anchors a tooltip at its start when the segment midpoint is in the first quarter' do
    arcs = described_class.new([{ label: 'Sheltered', value: 10, color: '#14558F' }, { label: 'Unsheltered', value: 90, color: '#3E94CF' }]).arcs

    expect(arcs.map { |a| a.tooltip[:anchor] }).to eq(['start', 'middle'])
    expect(arcs.first.tooltip.values_at(:rect_x, :width, :text_x)).to eq(['27.08', '32.40', '43.28'])
  end
end
