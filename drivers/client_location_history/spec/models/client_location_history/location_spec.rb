###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientLocationHistory::Location, type: :model do
  describe '#link_for (private)' do
    it 'escapes html in the interpolated client name' do
      location = described_class.new
      html = location.send(:link_for, '/clients/1', '<script>alert(1)</script>')

      expect(html).not_to include('<script>')
      expect(html).to include('&lt;script&gt;')
    end

    it 'escapes html in the interpolated path' do
      location = described_class.new
      html = location.send(:link_for, '/clients/1"><script>alert(1)</script>', 'Jane Doe')

      expect(html).not_to include('<script>')
      expect(html).to include('&lt;script&gt;')
    end

    it 'still builds a working anchor tag for ordinary input' do
      location = described_class.new
      html = location.send(:link_for, '/clients/1', 'Jane Doe')

      expect(html).to eq('<a href="/clients/1" target="_blank">Jane Doe</a>')
    end
  end
end
