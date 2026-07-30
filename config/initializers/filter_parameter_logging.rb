###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Sensitive parameter names, filtered from the log file AND from ActiveRecord
# #inspect output.
sensitive_parameters = [
  :password,
  :passw,
  :secret,
  :token,
  :_key,
  :crypt,
  :salt,
  :encrypted,
  :certificate,
  :otp,
  :ssn,
  :dob,
  :date_of_birth,
  :first_name,
  :last_name,
  :FirstName,
  :LastName,
  :alternate_names,
  :medicaid,
  :medicare,
  :mass_health_id,
  :aliases,
  :birthdate,
  :hiv,
  :middle,
  :nick,
  :cell,
  :phone,
  :email,
  :zip,
].freeze

Rails.application.config.filter_parameters += sensitive_parameters

# Filter the same attributes in ActiveRecord's #inspect output. Set once on
# ActiveRecord::Base rather than per-model: Rails 8.1's `filter_attributes=` appends
# "model.attr" entries back into config.filter_parameters, but it skips Base, so this
# avoids that list growing on every model load / code reload.
ActiveSupport.on_load(:active_record) do
  self.filter_attributes = sensitive_parameters
end
