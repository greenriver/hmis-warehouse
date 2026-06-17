###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Menu::Item, type: :model do
  describe '#collapse_regex' do
    it 'does not add a leading alternation when only a match pattern is present' do
      item = described_class.new(match_pattern: 'reports', paths: [], children: [])

      expect(item.collapse_regex.source).to eq('reports')
    end

    it 'matches both child paths and the appended match pattern' do
      child = described_class.new(path: '/reports', children: [])
      item = described_class.new(children: [child], match_pattern: 'reports/\d+', paths: [])

      regex = item.collapse_regex

      expect(regex.match?('/reports')).to be_truthy
      expect(regex.match?('reports/123')).to be_truthy
    end
  end
end
