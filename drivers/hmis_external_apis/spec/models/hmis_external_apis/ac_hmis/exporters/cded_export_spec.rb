###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CdedExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:subject) { HmisExternalApis::AcHmis::Exporters::CdedExport.new }
  let!(:cded) { create :hmis_custom_data_element_definition, label: 'A string', data_source: ds, owner_type: 'Hmis::Hud::Service', field_type: :string, form_definition_identifier: 'my_form' }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets cdeds' do
    subject.run!
    expect(subject.send(:cdeds).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)

    expect(result.length).to eq(1)
    expect(result.first['CustomFieldKey']).to eq(cded.key)
    expect(result.first['FieldType']).to eq('string')
    expect(result.first['RecordType']).to eq('Service')
    expect(result.first['Label']).to eq(cded.label)
    expect(result.first['AssessmentKey']).to eq(cded.form_definition_identifier)
  end
end
