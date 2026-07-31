# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::FieldCatalog do
  describe '#field_for' do
    it 'returns nil for an unregistered PSDE key' do
      # Unregistered keys fall back to the raw expression editor rather than
      # hydrating into a clause with missing type metadata.
      expect(described_class.new.field_for('psde.not_registered')).to be_nil
    end
  end
end
