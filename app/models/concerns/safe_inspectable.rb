###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
