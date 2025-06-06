# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::RemoteCredentials::ExternalLink do
  describe 'attribute assignment' do
    it 'assigns aliased attributes correctly' do
      link = described_class.new(
        link_base: 'https://example.com',
      )
      expect(link.link_base).to eq('https://example.com')
    end
  end
end
