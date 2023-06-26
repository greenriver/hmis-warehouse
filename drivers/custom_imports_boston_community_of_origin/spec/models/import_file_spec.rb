###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'drivers/custom_imports_boston_community_of_origin/spec/fixtures'
  config.hook_into :webmock
end

RSpec.describe CustomImportsBostonCommunityOfOrigin::ImportFile, type: :model do
  it 'imports rows from file' do
    importer = CustomImportsBostonCommunityOfOrigin::ImportFile.new(summary: [])
    import(importer, 'locations.csv')

    expect(CustomImportsBostonCommunityOfOrigin::Row.count).to eq(3)
  end

  describe 'with context' do
    let!(:wc) { create :fixed_warehouse_client }
    let!(:e1) { create :hud_enrollment, personal_id: wc.source.personal_id, enrollment_id: 'E-1', data_source_id: wc.source.data_source_id }
    let!(:e2) { create :hud_enrollment, personal_id: wc.source.personal_id, enrollment_id: 'E-2', data_source_id: wc.source.data_source_id, last_permanent_zip: '05301' }

    it 'creates locations' do
      c1 = wc.source
      config = GrdaWarehouse::CustomImports::Config.create(data_source_id: c1.data_source_id)
      importer = CustomImportsBostonCommunityOfOrigin::ImportFile.create!(config: config, summary: [])
      import(importer, 'locations.csv')
      VCR.use_cassette('nominatim') do
        importer.class.process_locations
        GrdaWarehouse::Hud::Enrollment.maintain_location_histories
      end

      expect(importer.rows.first.client_location).to be_present
      expect(e2.client_location).to be_present
    end
  end

  def import(model, fixture)
    contents = File.read(::File.join('drivers/custom_imports_boston_community_of_origin/spec/fixtures', fixture))
    sheet = ::Roo::CSV.new(StringIO.new(contents))
    sheet.parse(headers: true).drop(1)
    model.load_csv(sheet)
  end
end
