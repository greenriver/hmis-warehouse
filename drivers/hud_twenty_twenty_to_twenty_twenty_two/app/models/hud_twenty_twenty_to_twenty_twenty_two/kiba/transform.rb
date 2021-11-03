###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Kiba::Transform
  module_function

  def up(source_class, source_config, transforms, dest_class, dest_config)
    Kiba.parse do
      source source_class, source_config

      transform(&:to_hash) # Make sure what the source returns is a hash
      transforms.each do |t|
        transform t
      end

      destination dest_class, dest_config
    end
  end
end
