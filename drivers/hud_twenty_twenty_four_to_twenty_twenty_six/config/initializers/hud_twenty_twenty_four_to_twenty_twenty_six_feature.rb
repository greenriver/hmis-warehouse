###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# HudTwentyTwentyFourToTwentyTwentySix driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_twenty_twenty_four_to_twenty_twenty_six)
#
# use with caution!
RailsDrivers.loaded << :hud_twenty_twenty_four_to_twenty_twenty_six

Rails.application.reloader.to_prepare do
  # All of the CSVVersions we have seen for HUD 2024 files
  [
    '2024 (v1.3 csv)',
    '2024 v1.2',
    '2024 v1.3',
    '2024 v1.4',
    '2024 v1.5',
    '2024 v1.6',
    '2024',
    '2024v1.2',
    'FY 2024 1.3',
    'FY2024',
    'Y2024',
  ].each do |version|
    Importers::HmisAutoMigrate.add_migration(version, 'HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer')
  end
end
