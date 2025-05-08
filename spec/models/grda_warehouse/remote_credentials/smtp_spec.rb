# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::RemoteCredentials::Smtp do
  describe 'attribute assignment' do
    it 'assigns aliased attributes correctly' do
      smtp = described_class.new(
        server: 'smtp.example.com',
        from: 'noreply@example.com',
      )
      expect(smtp.server).to eq('smtp.example.com')
      expect(smtp.from).to eq('noreply@example.com')
    end
  end
end
