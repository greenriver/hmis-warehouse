###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# HudTwentyTwentyToTwentyTwentyTwo driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_twenty_twenty_to_twenty_twenty_two)
#
# use with caution!
RailsDrivers.loaded << :hud_twenty_twenty_to_twenty_twenty_two

Rails.application.reloader.to_prepare do
  Importers::HmisAutoMigrate.add_migration('2020', 'HudTwentyTwentyToTwentyTwentyTwo::CsvTransformer')
end
