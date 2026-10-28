###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Configuration, type: :model do
  describe '#alt_aha_model_version' do
    subject(:version) { described_class.new.alt_aha_model_version }

    def set_property(value_input)
      AppConfigProperty.create!(key: 'ac_hmis/alt_aha_model_version', value_input: value_input)
    end

    it 'is 1 when unset' do
      expect(version).to eq(1)
    end

    it 'reads an integer' do
      set_property('2')
      expect(version).to eq(2)
    end

    it 'accepts the string form' do
      set_property('"2"')
      expect(version).to eq(2)
    end

    ['3', '0', '"two"', 'true', '2.0', '[2]'].each do |value_input|
      it "raises on #{value_input}" do
        set_property(value_input)
        expect { version }.to raise_error(ArgumentError, /alt_aha_model_version/)
      end
    end
  end
end
