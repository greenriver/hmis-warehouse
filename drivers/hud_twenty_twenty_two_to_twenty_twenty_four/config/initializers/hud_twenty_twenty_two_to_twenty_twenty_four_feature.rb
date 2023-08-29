# The core app (or other drivers) can check the presence of the
# HudTwentyTwentyTwoToTwentyTwentyFour driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_twenty_twenty_two_to_twenty_twenty_four)
#
# use with caution!
RailsDrivers.loaded << :hud_twenty_twenty_two_to_twenty_twenty_four

# TODO: Enable after 2024 importer is available
#
# Rails.application.reloader.to_prepare do
#   # All of the CSVVersions we have seen for HUD 2022 files
#   [
#     '1.2',
#     '2022',
#     '2022 (v1.1 csv)',
#     '2022 v1.2',
#     'FY 2022 1.0',
#     'FY2022',
#     'FY2022v1.1',
#     'Y2022',
#     'v1.1',
#     'v1.2',
#   ].each do |version|
#     Importers::HmisAutoMigrate.add_migration(version, 'HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer')
#   end
# end
