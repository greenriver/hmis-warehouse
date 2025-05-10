# frozen_string_literal: true

module GrdaWarehouse
  # Represents a client search query with associated parameters
  #
  # This model stores search query parameters used for HMIS client searches.
  # It provides:
  # - Parameter validation and normalization
  # - Fingerprinting based on query content to allow finding existing searches
  # - ID encryption for secure URL sharing
  class ClientSearchQuery < GrdaWarehouseBase
    belongs_to :created_by, class_name: 'User'

    MAX_STRING_LENGTH = 100
    ALLOWED_PARAMS = ['q', 'client'].freeze
    ALLOWED_CLIENT_PARAMS = ['first_name', 'last_name', 'dob', 'ssn'].freeze

    validate :validate_params

    def encrypted_id
      raise 'Attempt to encrypt NULL id' unless id.present?

      ClientSearchQueryIdProtector.instance.encrypt(id.to_s)
    end

    def self.find_by_encrypted_id(encrypted_id)
      id = ClientSearchQueryIdProtector.instance.decrypt(encrypted_id)
      return nil unless id.present?

      find_by(id: id)
    end

    # @param params [ActionController::Parameters] request params
    # @return [ActionController::Parameters, nil] Permitted parameters or nil if no valid params present
    def self.permit_params(params)
      params.permit(*ALLOWED_PARAMS, client: ALLOWED_CLIENT_PARAMS).presence
    end

    def self.find_or_create_by_params(params, user:)
      norm = normalize_params(params.to_h)
      fingerprint = generate_fingerprint(norm)

      # Validate params first
      instance = new(params: norm)
      instance.validate_params
      return instance if instance.errors.any?

      upsert(
        { fingerprint: fingerprint, params: norm, created_by_id: user.id },
        unique_by: :fingerprint,
        on_duplicate: Arel.sql('params = EXCLUDED.params, created_by_id = EXCLUDED.created_by_id'),
      )

      find_by!(fingerprint: fingerprint)
    end

    def self.generate_fingerprint(params)
      Digest::SHA256.hexdigest(params.to_json)
    end

    def self.normalize_params(params)
      return {} if params.nil?

      params.transform_values do |v|
        case v
        when Hash
          normalize_params(v)
        when String
          v.strip
        else
          v
        end
      end.reject { |_, v| v.blank? }.sort.to_h
    end

    def validate_params
      return if params.blank?

      # Validate top-level parameters
      invalid_params = params.keys - ALLOWED_PARAMS
      errors.add(:params, "contains invalid parameters: #{invalid_params.join(', ')}") if invalid_params.any?

      # Validate client parameters if present
      if params['client'].present?
        invalid_client_params = params['client'].keys - ALLOWED_CLIENT_PARAMS
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
  end
end
