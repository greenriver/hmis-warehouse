###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::SystemColor, type: :model do
  describe 'background_color validation' do
    it 'accepts 3- and 6-digit hex in either case' do
      ['#abc', '#ABCDEF', '#96a1fa'].each do |value|
        expect(described_class.new(slug: 'race-0', background_color: value)).to be_valid, value
      end
    end

    it 'rejects values that are not a hex color' do
      ['red', '#abcd', '#fff}</style><b>x</b>', '#fff; } body { display: none'].each do |value|
        color = described_class.new(slug: 'race-0', background_color: value)
        expect(color).not_to be_valid, value
        expect(color.errors[:background_color]).to be_present
      end
    end
  end

  describe '.as_css' do
    it 'omits rows whose stored color is not a hex color' do
      described_class.create!(slug: 'race-0', background_color: '#123456')
      # update_column skips the format validation
      described_class.create!(slug: 'race-1', background_color: '#000000').
        update_column(:background_color, '#fff}</style><b>x</b>')

      css = described_class.as_css

      expect(css).to include('.race-0 { background-color: #123456; ')
      expect(css).not_to include('race-1')
      expect(css).not_to include('</style')
    end
  end
end
