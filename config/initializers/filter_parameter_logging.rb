Rails.logger.debug "Running initializer in #{__FILE__}"

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
    :password, :password_confirmation, :otp_attempt
]
