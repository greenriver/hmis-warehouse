###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'kiba-common/sources/csv'
require 'kiba-common/sources/enumerable'

module HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::Transform
  module_function

  def up(source_class, source_config, transforms, dest_class, dest_config)
    Kiba.parse do
      if source_class == Kiba::Common::Sources::Enumerable # Special case to let us pass an array to an enumerable
        source(source_class, source_config)
      elsif source_config.is_a?(Class)
        source(source_class, source_config)
      else
        source(source_class, **source_config)
      end

      transform(&:to_hash) # Make sure what the source returns is a hash
      transforms.each do |t|
        transform(*t)
      end

      if dest_config.is_a?(Class)
        destination(dest_class, dest_config)
      else
        destination(dest_class, **dest_config)
      end
    end
  end
end
