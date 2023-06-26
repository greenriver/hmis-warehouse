###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::ClientExport, type: :model do
  let(:today) { Date.today }
  let!(:ds) { create(:hmis_data_source) }
  let!(:client) { create(:hmis_hud_client, data_source: ds, DateCreated: today) }
  let(:subject) { HmisExternalApis::AcHmis::Exporters::ClientExport.new }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets clients' do
    subject.run!
    expect(subject.send(:clients).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
    expect(result.first['FirstName']).to eq(client.first_name)
  end

  it 'includes most recently updated address' do
    not_found = create(:hmis_hud_custom_client_address, client: client)
    found = create(:hmis_hud_custom_client_address, client: client)
    subject.run!
    expect(output).to include(found.line1)
    expect(output).to_not include(not_found.line1)
  end

  it 'includes MCIID' do
    mci = create(:mci_external_id, source: client)
    irrelevant = create(:ac_warehouse_external_id, source: client)
    subject.run!
    expect(output).to include(mci.value)
    expect(output).to_not include(irrelevant.value)
  end

  it 'formats dates correctly' do
    subject.run!
    expect(output).to include(today.strftime('%Y-%m-%d'))
  end
end
