###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::CustomDataElementsImporter, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:dir) { 'drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/custom_data_elements' }
  let(:mper_creds) { create(:ac_hmis_mper_credential) }

  it 'has a smoke test' do
    Dir.chdir(dir) do
      importer = HmisExternalApis::AcHmis::Importers::CustomDataElementsImporter.new(dir: '.', key: 'data.zip', etag: '12345')
      importer.run!
    end
    expect(GrdaWarehouse::Hud::CustomDataELement.count).to eq(1)
  end
end
