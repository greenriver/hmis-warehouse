###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Form::RecordType, type: :model do
  describe 'find!' do
    it 'returns the record type' do
      expect(described_class.find!('CLIENT').owner_type).to eq('Hmis::Hud::Client')
    end

    it 'raises a message naming the valid record types' do
      expect { described_class.find!('PROJECT') }.
        to raise_error(/Invalid record type 'PROJECT'.*CLIENT/)
    end
  end

  # The schema's enum is maintained by hand. When it allows a value this struct doesn't define, a form can pass
  # schema validation and then fail on publish or seed when the record type is looked up.
  it 'matches the record_type enum in the form definition JSON schema' do
    schema = JSON.parse(Rails.root.join('drivers/hmis_external_apis/public/schemas/form_definition.json').read)
    schema_record_types = schema.dig('$defs', 'mapping', 'properties', 'record_type', 'enum')

    expect(schema_record_types).to match_array(described_class.all.map(&:id))
  end
end
