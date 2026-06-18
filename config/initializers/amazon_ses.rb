###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Rails.logger.debug "Running initializer in #{__FILE__}"

Aws::Rails.add_action_mailer_delivery_method(:aws_sdk, region: "us-east-1")
