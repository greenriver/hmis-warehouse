###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    travel_to Time.local(2020, 1, 1) do
      @loader = import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/remap_hud_keys',
        data_source: FactoryBot.create(:remap_hud_keys_ds),
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end
  end

  it 'remaps the client PersonalID to a stable de-identified value' do
    expect(GrdaWarehouse::Hud::Client.source.first.PersonalID).to eq(Digest::MD5.hexdigest('PersonalID--TEST-SRC--C-1'))
  end

  it 'remaps the same PersonalID identically on the enrollment' do
    expect(GrdaWarehouse::Hud::Enrollment.first.PersonalID).to eq(Digest::MD5.hexdigest('PersonalID--TEST-SRC--C-1'))
  end

  it 'remaps HouseholdID even though it is not any file\'s hud_key' do
    expect(GrdaWarehouse::Hud::Enrollment.first.HouseholdID).to eq(Digest::MD5.hexdigest('HouseholdID--TEST-SRC--H-1'))
  end
end
