###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HMIS-backed data source skips CustomDataElement import' do
  # Without `hmis_owned: true` the CSV import into an HMIS-backed data source silently soft-deletes
  # every pre-existing CustomDataElement(Definition) row for that data source,
  # because involved_warehouse_scope for these two custom files matches every
  # row regardless of what's in the incoming CSV.
  after(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  before(:all) do
    @data_source = create(:hmis_primary_data_source)

    # Rows already present for this data source before the import runs,
    # simulating data the HMIS app itself created. Neither is referenced by
    # the incoming CSV fixture, so a broken guard would flag them pending
    # deletion and purge them.
    @pre_existing_definition = create(
      :hud_custom_data_element_definition,
      data_source_id: @data_source.id,
      owner_type: 'GrdaWarehouse::Hud::Client',
      key: 'hmis_app_owned_field',
    )
    @pre_existing_element = create(
      :hud_custom_data_element,
      data_source_id: @data_source.id,
      custom_data_element_definition: @pre_existing_definition,
      owner_type: 'GrdaWarehouse::Hud::Client',
    )

    temp_dir = Dir.mktmpdir
    FileUtils.cp_r('drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/custom_files/.', temp_dir)

    import_hmis_csv_fixture(
      temp_dir,
      version: 'AutoMigrate',
      data_source: @data_source,
      run_jobs: true,
      stop_version: '2026',
    )
    FileUtils.rm_rf(temp_dir)
  end

  it 'does not create the CustomDataElementDefinition row present in the CSV' do
    expect(GrdaWarehouse::Hud::CustomDataElementDefinition.where(data_source_id: @data_source.id, key: 'reason_for_exit')).not_to exist
  end

  it 'does not create the CustomDataElement row present in the CSV' do
    expect(GrdaWarehouse::Hud::CustomDataElement.where(data_source_id: @data_source.id, CustomDataElementID: 'A1001')).not_to exist
  end

  it 'does not soft-delete the pre-existing CustomDataElementDefinition' do
    expect(@pre_existing_definition.reload.DateDeleted).to be_nil
  end

  it 'does not soft-delete the pre-existing CustomDataElement' do
    expect(@pre_existing_element.reload.DateDeleted).to be_nil
  end

  it 'still imports other custom files unrelated to CustomDataElement' do
    client = GrdaWarehouse::Hud::Client.find_by(data_source_id: @data_source.id, PersonalID: '2f4b963171644a8b9902bdfe79a4b403')
    expect(client.GenderNone).to eq(8)
  end
end
