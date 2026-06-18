###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

ActsAsTaggableOn.setup do |config|
  # Store the tags in the warehouse
  config.base_class = 'GrdaWarehouseBase'
end
