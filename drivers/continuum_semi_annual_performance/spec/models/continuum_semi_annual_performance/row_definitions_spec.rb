###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContinuumSemiAnnualPerformance::RowDefinitions do
  def labels(set, type) = described_class.rows(set, type).map { |r| r[:label] }

  it 'returns rows and their cells frozen so the cache cannot be mutated' do
    row = described_class.rows(:mid_year, :es).find { |r| r[:cells] }

    expect(row).to be_frozen
    expect(row[:cells]).to be_frozen
    expect(row[:cells]).to all(be_frozen)
  end

  it 'starts the SO end-of-year tab with its outreach heading' do
    first = described_class.rows(:end_of_year, :so).first

    expect(first).to include(label: 'Street Outreach and Emergency Shelter', header: true, level: 1)
  end

  it 'gives RRH the move-in rows and SO the engagement rows, not each other' do
    expect(labels(:end_of_year, :rrh)).to include('Average Length of Time to Housing')
    expect(labels(:end_of_year, :rrh)).not_to include('Total Persons Contacted')
    expect(labels(:end_of_year, :so)).to include('Total Persons Contacted')
  end

  it 'nests Q13a1 sub-headings under the question heading' do
    rows = described_class.rows(:end_of_year, :es).select { |r| r[:header] && r[:label].start_with?('Q13a1', 'Adults Totals') }

    expect(rows.map { |r| [r[:label], r[:level]] }).to eq(
      [
        ['Q13a1: Physical and Mental Conditions (At Start)', 1],
        ['Q13a1 [Column C] - Adults without Children', 2],
        ['Q13a1 [Column D] - Adults in HH with Children & Adults', 2],
        ['Adults Totals', 2],
      ],
    )
  end

  it 'uses the corrected Q6c, Q12 and CE Q10 cells' do
    by_label = ->(set, type, label) { described_class.rows(set, type).find { |r| r[:label] == label }[:cells] }

    expect(by_label.call(:end_of_year, :es, 'Income and Sources at Annual Assessment Total')).to eq([{ report: 'apr', table: 'Q6c', cell: 'E4' }])
    expect(by_label.call(:end_of_year, :es, 'White AND Black, African American, or African')).to eq([{ report: 'apr', table: 'Q12', cell: 'B23' }])
    ehv = described_class.rows(:end_of_year, :ce_tab).select { |r| r[:label] == 'Referral to Emergency Housing Voucher (EHV)' }.map { |r| r[:cells].first[:cell] }
    expect(ehv).to eq(['B20', 'C20', 'D20', 'E20'])
  end

  it 'expands SUM ranges into every cell between the endpoints' do
    age_total = described_class.rows(:mid_year, :hp).find { |r| r[:label] == 'Age: Total' }

    expect(age_total[:op]).to eq(:sum)
    expect(age_total[:cells].map { |c| c[:cell] }).to eq(('2'..'12').map { |n| "B#{n}" })
  end

  it 'lists the generator questions each sub-report must build' do
    expect(described_class.questions(:mid_year, :es)).to eq(['Question 7', 'Question 8', 'Question 11', 'Question 23'])
    expect(described_class.questions(:end_of_year, :ce_tab)).to eq(['Question 7', 'Question 8', 'Question 10'])
  end
end
