###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::PathwaysExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:p1) { create(:hmis_hud_project, data_source: ds) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:client2) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:client3) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let(:subject) { HmisExternalApis::AcHmis::Exporters::PathwaysExport.new }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  let!(:pathway_definitions) do
    cdeds = [
      'client_pathway_1',
      'client_pathway_2',
      'client_pathway_3',
    ].map { |key| create(:hmis_custom_data_element_definition, key: key, field_type: :string, owner_type: 'Hmis::Hud::Client') }

    cdeds << [
      'client_pathway_1_date',
      'client_pathway_2_date',
      'client_pathway_3_date',
    ].map { |key| create(:hmis_custom_data_element_definition, key: key, field_type: :date, owner_type: 'Hmis::Hud::Client') }

    cdeds << [
      'client_pathway_1_narrative',
      'client_pathway_2_narrative',
      'client_pathway_3_narrative',
    ].map { |key| create(:hmis_custom_data_element_definition, key: key, field_type: :text, owner_type: 'Hmis::Hud::Client') }

    cdeds.flatten.index_by(&:key)
  end

  it 'collects clients with pathways' do
    create(:hmis_custom_data_element, owner: client, data_element_definition: pathway_definitions['client_pathway_1'])
    subject.run!
    expect(subject.send(:clients_with_pathways)).to contain_exactly(client)
  end

  it 'doesnt fail if no clients have pathways' do
    subject.run!
    expect(subject.send(:clients_with_pathways).length).to eq(0)
  end

  it 'makes a csv' do
    pathway1 = create(:hmis_custom_data_element, owner: client, value_string: 'xyz', data_element_definition: pathway_definitions['client_pathway_1'])
    pathway2date = create(:hmis_custom_data_element, owner: client, value_date: 1.week.ago, data_element_definition: pathway_definitions['client_pathway_1_date'])
    pathway2 = create(:hmis_custom_data_element, owner: client, value_string: 'abc', data_element_definition: pathway_definitions['client_pathway_2'])
    pathway2narrative = create(:hmis_custom_data_element, owner: client, value_text: 'narrative note', data_element_definition: pathway_definitions['client_pathway_2_narrative'])

    subject.run!
    result = CSV.parse(output, headers: true)

    expect(result.length).to eq(1)
    expect(result.first['Pathway1']).to eq(pathway1.value_string)
    expect(result.first['Pathway1_Date']).to eq(pathway2date.value_date.strftime('%Y-%m-%d'))
    expect(result.first['Pathway1_Narrative']).to be_nil
    expect(result.first['Pathway1_DateUpdated']).to eq(pathway1.date_updated.strftime('%Y-%m-%d %H:%M:%S'))
    expect(result.first['Pathway2']).to eq(pathway2.value_string)
    expect(result.first['Pathway2_Date']).to be_nil
    expect(result.first['Pathway2_Narrative']).to eq(pathway2narrative.value_text)
    expect(result.first['Pathway2_DateUpdated']).to eq(pathway2.date_updated.strftime('%Y-%m-%d %H:%M:%S'))
    expect(result.first['Pathway3']).to be_nil
    expect(result.first['Pathway3_Date']).to be_nil
    expect(result.first['Pathway3_Narrative']).to be_nil
    expect(result.first['Pathway3_DateUpdated']).to be_nil
  end
end
