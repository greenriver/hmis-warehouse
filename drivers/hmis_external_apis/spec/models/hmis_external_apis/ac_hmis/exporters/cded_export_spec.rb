#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CdedExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:subject) { HmisExternalApis::AcHmis::Exporters::CdedExport.new }
  let!(:cded) { create :hmis_custom_data_element_definition, label: 'A string', data_source: ds, owner_type: 'Hmis::Hud::Service', field_type: :string }
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
  end
end
