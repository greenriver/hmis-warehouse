###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Migration::MciMappingImporter, type: :model do
  let!(:mci_cred) { create(:ac_hmis_mci_credential) }
  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:io) { File.open('drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/migration/mci-unique-id-to-mci-id-mappings.xls') }
  let(:subject) { HmisExternalApis::AcHmis::Importers::Migration::MciMappingImporter.new(io: io) }

  # Reference for mappings in xls file:
  # 1234567 -> 7654321
  # 13243546 -> 34
  # 1818181 -> nothing
  # 171717 -> 1555
  # 171717 -> 1666

  it 'makes an MCI ID' do
    create(:mci_unique_id_external_id, source: client, value: '1234567')

    subject.run!

    scope = client.external_ids.where(namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID)
    expect(scope.count).to eq(1)
    expect(scope.first.value).to eq('7654321')
  end

  it 'creates multiple MCI IDs' do
    create(:mci_unique_id_external_id, source: client, value: '171717')

    subject.run!

    client.reload
    expect(client.ac_hmis_mci_unique_id.value).to eq('171717')
    expect(client.ac_hmis_mci_ids.map(&:value)).to contain_exactly('1555', '1666')
  end

  it 'does nothing if the MCI ID is already there' do
    create(:mci_unique_id_external_id, source: client, value: '1234567')
    create(:mci_external_id, source: client, value: '7654321', remote_credential: mci_cred)

    subject.run!

    scope = client.external_ids.where(namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID)
    expect(scope.count).to eq(1)
    expect(scope.first.value).to eq('7654321')
  end

  it "works correctly when a mapping isn't actually supplied" do
    create(:mci_unique_id_external_id, source: client, value: '1818181')

    subject.run!

    expect(client.external_ids.where(namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID).first&.value).to be_nil
  end
end