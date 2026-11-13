###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Rails.logger.debug "Running initializer in #{__FILE__}"

Kaminari.configure do |config|
  config.window = 2
  # config.outer_window = 0
end
