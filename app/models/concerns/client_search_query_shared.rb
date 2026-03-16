###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientSearchQueryShared
  extend ActiveSupport::Concern
  included do
    MAX_STRING_LENGTH = 100

    validate :validate_params

    def self.find_or_create_by_normalized_params(params, user:)
      # Validate params first
      instance = new(params: params)
      instance.validate_params
      return instance if instance.errors.any?

      fingerprint = generate_fingerprint(params)
      upsert(
        { fingerprint: fingerprint, params: params, created_by_id: user.id },
        unique_by: :fingerprint,
        on_duplicate: Arel.sql('params = EXCLUDED.params, created_by_id = EXCLUDED.created_by_id'),
      )

      find_by!(fingerprint: fingerprint)
    end

    def self.generate_fingerprint(params)
      Digest::SHA256.hexdigest(params.to_json)
    end

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
          errors.add(:params, "#{field} is too long (max #{self.class::MAX_STRING_LENGTH} characters)") if value.length > self.class::MAX_STRING_LENGTH
        when Hash
          validate_string_lengths(value, prefix ? "#{prefix}.#{key}" : key)
        end
      end
    end
  end
end
