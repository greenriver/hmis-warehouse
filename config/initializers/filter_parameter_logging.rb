Rails.logger.debug "Running initializer in #{__FILE__}"

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :access_key_id,
  :api_key,
  :family_name,
  :first_name,
  :FirstName,
  :ftp_pass,
  :given_name,
  :last_name,
  :LastName,
  :middle_name,
  :MiddleName,
  :otp_attempt,
  :pass,
  :password,
  :password_confirmation,
  :s3_access_key_id,
  :s3_secret_access_key,
  :secret_access_key,
  :SSN,
  :ssn,
  :zip_file_password,
  :zip_file_password,
]
