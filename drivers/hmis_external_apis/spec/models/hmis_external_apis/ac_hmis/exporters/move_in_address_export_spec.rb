###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::MoveInAddressExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:enrollment) { create(:hmis_hud_enrollment, data_source: ds, client: client) }
  let!(:address) { create(:hmis_move_in_address, data_source: ds, enrollment: enrollment, client: client) }
  let(:subject) { HmisExternalApis::AcHmis::Exporters::MoveInAddressExport.new }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets move in addresses' do
    subject.run!
    expect(subject.send(:move_in_addresses).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
    expect(result.first['PersonalID']).to eq(client.warehouse_id.to_s)
  end

  it 'excludes move-in addresses on WIP enrollments' do
    wip_enrollment = create(:hmis_hud_wip_enrollment, data_source: ds, client: client)
    create(:hmis_move_in_address, client: client, enrollment: wip_enrollment)

    subject.run!

    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
  end

  it 'does not include other addresses' do
    create(:hmis_hud_custom_client_address, client: client)
    create(:hmis_hud_custom_client_address, client: client)

    subject.run!

    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)
  end

  it 'works for client with multiple move-in addresses' do
    # second enrollment with move-in address
    e2 = create(:hmis_hud_enrollment, data_source: ds, client: client)
    create(:hmis_move_in_address, data_source: ds, client: client, enrollment: e2)

    # cruft
    create(:hmis_hud_wip_enrollment, data_source: ds, client: client)
    create(:hmis_hud_wip_enrollment, data_source: ds, client: client)
    create(:hmis_hud_custom_client_address, client: client)

    subject.run!

    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(2)
  end
end
