# frozen_string_literal: true

module GrdaWarehouse
  class ClientSearchQuery < GrdaWarehouseBase
    belongs_to :user

    MAX_STRING_LENGTH = 100
    ALLOWED_PARAMS = ['q', 'client'].freeze
    ALLOWED_CLIENT_PARAMS = ['first_name', 'last_name', 'dob', 'ssn'].freeze

    validate :validate_params

    scope :for_user, ->(user) { where(user: user) }

    # @param params [ActionController::Parameters] request params
    # @return [ActionController::Parameters, nil] Permitted parameters or nil if no valid params present
    def self.permit_params(params)
      params.permit(*ALLOWED_PARAMS, client: ALLOWED_CLIENT_PARAMS).presence
    end

    def self.find_or_create_by_params!(params)
      norm = normalize_params(params.to_h)
      fingerprint = generate_fingerprint(norm)
      where(fingerprint: fingerprint).first_or_create!(params: norm)
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

    private

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
      params.each do |key, value|
        case value
        when String
          errors.add(:params, "#{key} is too long (max #{MAX_STRING_LENGTH} characters)") if value.length > MAX_STRING_LENGTH
        when Hash
          value.each do |subkey, subvalue|
            if subvalue.is_a?(String)
              errors.add(:params, "#{key}.#{subkey} is too long (max #{MAX_STRING_LENGTH} characters)") if subvalue.length > MAX_STRING_LENGTH
            end
          end
        end
      end
    end
  end
end
