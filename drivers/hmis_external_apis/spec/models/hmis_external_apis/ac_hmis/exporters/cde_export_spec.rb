#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CdeExport, type: :model do
  let(:today) { Date.current }
  let!(:ds) { create(:hmis_data_source) }
  let(:subject) { HmisExternalApis::AcHmis::Exporters::CdeExport.new }

  let!(:u1) { create :hmis_hud_user, data_source: ds, user_email: 'test@example.com' }
  let!(:c1) { create :hmis_hud_client, data_source: ds, user: u1 }
  let!(:o1) { create :hmis_hud_organization, data_source: ds, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds, organization: o1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds, project: p1 }
  let!(:hud_service) { create :hmis_hud_service, data_source: ds, client: c1, enrollment: e1 }

  let!(:creation_time) { Time.current }

  let!(:cded) { create :hmis_custom_data_element_definition, label: 'A string', data_source: ds, owner_type: 'Hmis::Hud::Service', field_type: :string }
  let!(:cde1) { create :hmis_custom_data_element, data_element_definition: cded, owner: hud_service, data_source: ds, value_string: 'First value', DateCreated: creation_time, DateUpdated: creation_time }

  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets cdes' do
    subject.run!
    expect(subject.send(:cdes).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
    expect(result.first['ResponseID']).to eq(cde1.id.to_s)
    expect(result.first['CustomFieldKey']).to eq(cded.key)
    expect(result.first['RecordType']).to eq('Service')
    expect(result.first['RecordId']).to eq(hud_service.id.to_s)
    expect(result.first['Response']).to eq('First value')
    expect(result.first['DateCreated']).to eq(creation_time.strftime('%Y-%m-%d %H:%M:%S'))
    expect(result.first['DateUpdated']).to eq(creation_time.strftime('%Y-%m-%d %H:%M:%S'))
  end

  context 'when there are multiple CDEs with different owners and CDEDs' do
    let!(:hud_service_2) { create :hmis_hud_service, data_source: ds, client: c1, enrollment: e1 }
    let!(:cded2) { create :hmis_custom_data_element_definition, label: 'A different CDED', data_source: ds, owner_type: 'Hmis::Hud::Service', field_type: :string }
    let!(:cde2) { create :hmis_custom_data_element, data_element_definition: cded2, owner: hud_service_2, data_source: ds, value_string: 'A new value' }

    it 'does not do a db lookup per iteration' do
      expect do
        subject.run!
        expect(subject.send(:cdes).length).to eq(2)
      end.to make_database_queries(count: 4)
    end
  end

  context 'when there is a CDE with a date type' do
    let!(:cded) { create :hmis_custom_data_element_definition, label: 'date!', data_source: ds, owner_type: 'Hmis::Hud::Service', field_type: :date }
    let!(:cde1) { create :hmis_custom_data_element, data_element_definition: cded, owner: hud_service, data_source: ds, value_date: Date.today }

    it 'displays the date correctly' do
      subject.run!
      result = CSV.parse(output, headers: true)
      expect(result.length).to eq(1)
      expect(result.first['Response']).to eq(Date.today.strftime('%Y-%m-%d'))
    end
  end
end
