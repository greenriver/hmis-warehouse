###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# some objects on too large to show
module SafeInspectable
  extend ActiveSupport::Concern

  def to_s
    inspect
  end

  def inspect
    "#{self.class.name}##{object_id}"
  end
end
