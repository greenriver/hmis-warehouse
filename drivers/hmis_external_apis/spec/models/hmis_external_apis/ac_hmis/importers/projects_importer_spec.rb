###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::ProjectsImporter, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:dir) { 'drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/projects' }

  it 'has a smoke test' do
    Dir.chdir(dir) do
      importer = HmisExternalApis::AcHmis::Importers::ProjectsImporter.new(dir: '.', key: 'data.zip', etag: '12345')
      importer.run!
    end

    expect(GrdaWarehouse::Hud::Project.count).to eq(1)
    expect(GrdaWarehouse::Hud::Funder.count).to eq(1)
    expect(GrdaWarehouse::Hud::Organization.count).to eq(1)
    expect(Hmis::Hud::CustomDataElement.count).to eq(1)
    expect(Hmis::Hud::CustomDataElement.first.value_boolean).to be(false)
  end
end
