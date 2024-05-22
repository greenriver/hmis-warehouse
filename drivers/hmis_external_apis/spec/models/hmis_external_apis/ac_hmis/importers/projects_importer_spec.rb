###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::ProjectsImporter, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:dir) { 'drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/projects' }
  let(:invalid_data_dir) { 'drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/ac_hmis/importers/projects_invalid' }
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
    expect(GrdaWarehouse::Hud::ProjectCoc.count).to eq(1)
    expect(GrdaWarehouse::Hud::HmisParticipation.count).to eq(1)
    expect(GrdaWarehouse::Hud::CeParticipation.count).to eq(1)
    expect(Hmis::Hud::CustomDataElement.count).to eq(1)
    expect(Hmis::Hud::CustomDataElement.first.value_boolean).to be(false)
    expect(Hmis::ProjectUnitTypeMapping.count).to eq(2)
    expect(Hmis::Unit.count).to eq(10)
    expect(Hmis::Unit.where(unit_type: active_unit_type).count).to eq(10)

    # fixes incorrect hmis format
    expect(GrdaWarehouse::Hud::ProjectCoc.first.zip).to eq('11111')
    expect(GrdaWarehouse::Hud::CeParticipation.first.HousingAssessment).to eq(1)
  end

  it 'fails when funder dates are formatted incorrectly' do
    allow(Rails.logger).to receive(:fatal).and_return nil

    Dir.chdir(invalid_data_dir) do
      importer = HmisExternalApis::AcHmis::Importers::ProjectsImporter.new(dir: '.', key: 'data.zip', etag: '12345')
      expect do
        importer.run!
      end.to raise_error(StandardError, /Incorrectly formatted date in Funder.csv StartDate: 01-JUL-20/)
    end

    expect(Rails.logger).to have_received(:fatal).with('ProjectsImporter aborted before it finished.')
    expect(GrdaWarehouse::Hud::Project.count).to eq(0)
    expect(GrdaWarehouse::Hud::Funder.count).to eq(0)
  end
end
