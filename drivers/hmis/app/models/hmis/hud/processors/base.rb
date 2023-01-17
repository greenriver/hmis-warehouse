###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Processors::Base
  def initialize(processor)
    @processor = processor
  end

  def hud_name(field)
    field.underscore
  end

  def hud_type(field)
    type = schema.fields[field].type
    return nil unless type.respond_to?(:value_for)

    type
  end
end
