###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  Importers::HmisAutoMigrate.add_migration('2020', 'HudTwentyTwentyToTwentyTwentyTwo::CsvTransformer')
end
