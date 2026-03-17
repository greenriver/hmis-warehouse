# frozen_string_literal: true

module GrdaWarehouse
  # Represents a client search query with associated parameters
  #
  # This model stores search query parameters used for HMIS client searches.
  # It provides:
  # - Parameter validation and normalization
  # - Fingerprinting based on query content to allow finding existing searches
  # - Uses UUID primary key for secure URL sharing
  class ClientSearchQuery < GrdaWarehouseBase
    include ClientSearchQueryShared
    belongs_to :created_by, class_name: 'User'

    ALLOWED_PARAMS = ['q', 'client'].freeze
    ALLOWED_CLIENT_PARAMS = ['first_name', 'last_name', 'dob', 'ssn'].freeze

    # @param params [ActionController::Parameters] request params
    # @return [ActionController::Parameters, nil] Permitted parameters or nil if no valid params present
    def self.permit_params(params)
      params.permit(*ALLOWED_PARAMS, client: ALLOWED_CLIENT_PARAMS).presence
    end

    def self.find_or_create_by_params(params, user:)
      norm = normalize_params(params.to_h)

      # Validate params first
      instance = new(params: norm)
      instance.validate_params
      return instance if instance.errors.any?

      fingerprint = generate_fingerprint(norm)
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

    def query_params
      params.with_indifferent_access
    end
  end
end
