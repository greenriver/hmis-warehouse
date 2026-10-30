###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::UsCensusApi::Importer do
  it 'stores 2020-vintage zip code geoids under the prefix the zip code shapes use' do
    expect(described_class.normalized_geoid('860Z200US05401')).to eq('8600000US05401')
  end

  it 'leaves other geoids unchanged' do
    geoids = ['8600000US05401', '0500000US50007', '1600000US5010675']

    expect(geoids.map { |geoid| described_class.normalized_geoid(geoid) }).to eq(geoids)
  end

  describe '#run!' do
    let!(:state) { GrdaWarehouse::Shape::State.create!(stusps: 'VT', geoid: '50') }
    let!(:zip_code) { create :shape_zip_code, zcta5ce10: '05401', st_geoid: '50' }
    # CensusApi::Client.new validates the API key over HTTP, so the whole client is replaced.
    let(:client) { instance_double(CensusApi::Client, 'dataset=': nil) }
    let(:api_rows) { [{ 'GEO_ID' => '860Z200US05401', 'B01003_001E' => '5' }] }

    def create_variable(year)
      GrdaWarehouse::UsCensusApi::CensusVariable.create!(
        year: year,
        dataset: 'acs5',
        name: 'B01003_001E',
        label: 'Total',
        concept: 'Total population',
        census_group: 'B01003',
        census_attributes: 'B01003_001EA',
        internal_name: 'POP::TOTAL',
        created_on: Date.current,
      )
    end

    def run_importer(years)
      stub_const('GrdaWarehouse::UsCensusApi::Importer::THROTTLE', 0)
      allow(CensusApi::Client).to receive(:new).and_return(client)
      # _process_success deletes keys from each row, so every request gets fresh copies.
      allow(client).to receive(:where) { api_rows.map(&:dup) }
      described_class.new(years: years, datasets: ['acs5'], state_code: 'VT', levels: ['ZCTA5']).run!
    end

    it 'stores zip code values under the prefix the zip code shapes use' do
      create_variable(2020)

      run_importer([2020])

      expect(GrdaWarehouse::UsCensusApi::CensusValue.pluck(:full_geoid, :census_level, :value)).to eq([['8600000US05401', 'ZCTA5', 5]])
    end

    context 'with a real cache store' do
      # The test environment uses :null_store, so Rails.cache.read never hits.
      around do |example|
        original_cache_store = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
      ensure
        Rails.cache = original_cache_store
      end

      it 'requests the same geography again for a second year' do
        create_variable(2020)
        create_variable(2021)

        run_importer([2020, 2021])

        expect(client).to have_received(:where).twice
        expect(GrdaWarehouse::UsCensusApi::CensusValue.count).to eq(2)
      end
    end
  end
end
