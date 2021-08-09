###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#

require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'

module HudTwentyTwentyToTwentyTwentyTwo::Organization::Transform
  module_function

  def up(source_class, source_config, dest_class, dest_config)
    Kiba.parse do
      source source_class, source_config

      transform(&:to_hash) # The CSV loader returns something that is not quite a hash
      transform ::HudTwentyTwentyToTwentyTwentyTwo::Organization::RenameVictimServicesProvider

      destination dest_class, dest_config
    end
  end
end
