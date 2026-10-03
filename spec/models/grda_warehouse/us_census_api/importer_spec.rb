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
end
