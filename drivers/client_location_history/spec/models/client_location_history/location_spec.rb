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

  describe '#as_marker' do
    it 'escapes a malicious collected_by value' do
      location = described_class.new(collected_by: '<script>alert(1)</script>', located_on: Date.current)

      combined = location.as_marker[:label].join

      expect(combined).not_to include('<script>')
      expect(combined).to include('&lt;script&gt;')
    end

    it 'routes a malicious client name through name_for_label into link_for when :name is requested' do
      client = create(:hud_client)
      user = instance_double(User, can_view_clients?: true)
      pii_provider = instance_double(GrdaWarehouse::PiiProvider, full_name: '<script>alert(1)</script>')
      allow(client).to receive(:pii_provider).with(user: user).and_return(pii_provider)
      allow(client).to receive(:destination?).and_return(true)
      location = described_class.new(client: client, located_on: Date.current)

      combined = location.as_marker(user, [:name])[:label].join

      expect(combined).not_to include('<script>')
      expect(combined).to include('&lt;script&gt;')
    end
  end
end
