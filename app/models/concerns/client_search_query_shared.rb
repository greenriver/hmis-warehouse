###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared concern used by:
# - GrdaWarehouse::ClientSearchQuery model - client_search_queries table
# - Hmis::ClientSearchQuery model - hmis_client_search_queries table
#
# These models are expected to have the following attributes:
# - params
# - ALLOWED_PARAMS
# - ALLOWED_CLIENT_PARAMS if 'client' is an allowed param - todo @martha relates to other comment
module ClientSearchQueryShared
  extend ActiveSupport::Concern
  MAX_STRING_LENGTH = 100

  included do
    validate :validate_params

    def validate_params
      return if params.blank?

      # Validate top-level parameters
      invalid_params = params.keys - self.class::ALLOWED_PARAMS
      errors.add(:params, "contains invalid parameters: #{invalid_params.join(', ')}") if invalid_params.any?

      # Validate client parameters if present
      if params['client'].present?
        invalid_client_params = params['client'].keys - self.class::ALLOWED_CLIENT_PARAMS
        errors.add(:params, "contains invalid client parameters: #{invalid_client_params.join(', ')}") if invalid_client_params.any?
      end

      # Validate string lengths
      validate_string_lengths(params)
    end

    def validate_string_lengths(hash, prefix = nil)
      hash.each do |key, value|
        case value
        when String
          field = prefix ? "#{prefix}.#{key}" : key
          errors.add(:params, "#{field} is too long (max #{MAX_STRING_LENGTH} characters)") if value.length > MAX_STRING_LENGTH
        when Hash
          validate_string_lengths(value, prefix ? "#{prefix}.#{key}" : key)
        end
      end
    end

    def self.generate_fingerprint(params)
      Digest::SHA256.hexdigest(params.to_json)
    end
  end
end
