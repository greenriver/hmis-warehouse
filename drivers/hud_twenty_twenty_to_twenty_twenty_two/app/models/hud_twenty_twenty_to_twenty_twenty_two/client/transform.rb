###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Client::Transform
  module_function

  def up(source_class, source_config, dest_class, dest_config)
    Kiba.parse do
      source source_class, source_config

      transform(&:to_hash) # The CSV loader returns something that is not quite a hash
      transform ::HudTwentyTwentyToTwentyTwentyTwo::Client::Transform::TransformGenderToColumns

      destination dest_class, dest_config
    end
  end
end
