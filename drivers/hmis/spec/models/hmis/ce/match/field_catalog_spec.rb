# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::FieldCatalog do
  describe '#field_for' do
    it 'returns nil for an unregistered PSDE key' do
      # Unknown namespaced keys must not produce partial metadata that could
      # make an invalid expression appear editable in the structured builder.
      expect(described_class.new.field_for('psde.not_registered')).to be_nil
    end
  end
end
