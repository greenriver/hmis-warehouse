# Rails.logger.debug "Running initializer in #{__FILE__}"

Aws::Rails.add_action_mailer_delivery_method(:aws_sdk, region: "us-east-1")
