###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Version do
  describe '#safe_object / #safe_object_changes' do
    let(:version) { described_class.new(id: 1) }

    it 'returns the deserialized object when it loads cleanly' do
      allow(version).to receive(:object).and_return('entity_id' => 5)
      expect(version.safe_object).to eq('entity_id' => 5)
    end

    # A removed constant surfaces as ArgumentError under unsafe_load, NameError otherwise, and a
    # disallowed/unknown class under safe_load as Psych::DisallowedClass (a Psych::Exception).
    [
      ArgumentError.new('undefined class/module Foo::Bar'),
      NameError.new('uninitialized constant Foo::Bar'),
      Psych::DisallowedClass.new('load', 'Foo::Bar'),
      Psych::Exception.new('malformed YAML'),
    ].each do |error|
      it "returns nil (not raising) when object deserialization raises #{error.class}" do
        allow(version).to receive(:object).and_raise(error)
        expect(version.safe_object).to be_nil
      end

      it "returns nil (not raising) when object_changes deserialization raises #{error.class}" do
        allow(version).to receive(:object_changes).and_raise(error)
        expect(version.safe_object_changes).to be_nil
      end
    end

    it 're-raises errors that are not deserialization failures' do
      allow(version).to receive(:object).and_raise(RuntimeError, 'boom')
      expect { version.safe_object }.to raise_error(RuntimeError, 'boom')
    end
  end
end
