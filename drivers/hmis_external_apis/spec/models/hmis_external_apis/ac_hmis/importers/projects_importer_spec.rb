###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::ProjectsImporter, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:dir) { 'drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/projects' }
  let(:mper_creds) { create(:ac_hmis_mper_credential) }
  let!(:active_unit_type) do
    # Match ProjectUnitType.csv
    (active_unit_type, _inactive_unit_type) = ['42', '43'].map do |mper_unit_type_id|
      unit_type = create(:hmis_unit_type)
      HmisExternalApis::AcHmis::Mper.external_ids.create!(
        source: unit_type,
        value: mper_unit_type_id,
        remote_credential: mper_creds,
      )
      unit_type
    end
    active_unit_type
  end

  it 'has a smoke test' do
    Dir.chdir(dir) do
      importer = HmisExternalApis::AcHmis::Importers::ProjectsImporter.new(dir: '.', key: 'data.zip', etag: '12345')
      importer.run!
    end

    expect(GrdaWarehouse::Hud::Project.count).to eq(1)
    expect(GrdaWarehouse::Hud::Funder.count).to eq(1)
    expect(GrdaWarehouse::Hud::Organization.count).to eq(1)
    expect(GrdaWarehouse::Hud::Inventory.count).to eq(20)
    expect(Hmis::Hud::CustomDataElement.count).to eq(1)
    expect(Hmis::Hud::CustomDataElement.first.value_boolean).to be(false)
    expect(Hmis::ProjectUnitTypeMapping.count).to eq(2)
    expect(Hmis::Unit.count).to eq(10)
    expect(Hmis::Unit.where(unit_type: active_unit_type).count).to eq(10)
  end

  it 'updates existing project, and applies overrides' do
    # p1 ProjectID matches the fixture file
    start_date_override = 1.year.ago.to_date
    end_date_override = Date.yesterday
    p1 = create(:hmis_hud_project, data_source: ds, project_type: 0, project_id: '1000', act_as_project_type: 1, operating_start_date_override: start_date_override, operating_end_date_override: end_date_override)

    Dir.chdir(dir) do
      importer = HmisExternalApis::AcHmis::Importers::ProjectsImporter.new(dir: '.', key: 'data.zip', etag: '12345')
      importer.run!
    end

    expect(GrdaWarehouse::Hud::Project.count).to eq(1)
    p1.reload
    expect(p1.project_type).to eq(1)
    expect(p1.operating_start_date).to eq(start_date_override)
    expect(p1.operating_end_date).to eq(end_date_override)
  end
end
