###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientMatchHelper, type: :helper do
  describe '#match_legend' do
    let(:entries) do
      helper.match_legend.split('<br/>').map do |line|
        fragment = Nokogiri::HTML.fragment(line)
        abbr = fragment.at_css('abbr')
        { classes: abbr['class'].split, title: abbr['title'], symbol: abbr.text, label: fragment.text.split(': ', 2).last, style: abbr['style'] }
      end
    end

    it 'renders a flag class and title for every evidence state with no inline style' do
      expect(entries.map { |e| [e[:label], e[:classes], e[:title]] }).to eq(
        [
          ['Exact match - strong evidence for', ['match-flag', 'match-flag-strong-for'], 'strong evidence for/exact match: -10'],
          ['Strong evidence for', ['match-flag', 'match-flag-strong-for'], 'strong evidence for: -10'],
          ['Exact match - evidence for', ['match-flag', 'match-flag-for'], 'evidence for/exact match: -1'],
          ['Evidence for', ['match-flag', 'match-flag-for'], 'evidence for: -1'],
          ['Exact match - neutral', ['match-flag', 'match-flag-neutral'], 'neutral/exact match: 0'],
          ['Neutral', ['match-flag', 'match-flag-neutral'], 'neutral: 0'],
          ['Evidence against', ['match-flag', 'match-flag-against'], 'evidence against: 1'],
          ['Strong evidence against', ['match-flag', 'match-flag-strong-against'], 'strong against: 10'],
        ],
      )
      expect(entries.map { |e| e[:style] }.uniq).to eq([nil])
    end

    it 'shows equals signs for exact matches and the evidence symbol otherwise' do
      expect(entries.map { |e| e[:symbol].delete("\u00A0") }).to eq(['==', '++', '=', '+', '=', '~', '-', '--'])
    end
  end
  describe '#match_contribution_flags' do
    it 'renders nothing when there is no score and the fields differ' do
      match = double(
        score_contribution: nil,
        destination_client: double(FirstName: 'Ann'),
        source_client: double(FirstName: 'Anna'),
      )

      expect(helper.match_contribution_flags(match, :FirstName)).to eq('')
    end
  end
end
