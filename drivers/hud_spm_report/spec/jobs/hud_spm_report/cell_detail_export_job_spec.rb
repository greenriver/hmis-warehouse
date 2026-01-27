# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::CellDetailExportJob, type: :job do
  describe '#perform' do
    it 'uses correct export scope' do
      expect(described_class.new.send(:export_scope)).to eq(HudSpmReport::DocumentExports::CellDetailExport)
    end
  end
end
