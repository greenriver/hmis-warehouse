# frozen_string_literal: true

module Hmis
  class ClientSearchQuery < GrdaWarehouseBase
    include ClientSearchQueryShared
    belongs_to :created_by, class_name: 'Hmis::User'
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    ALLOWED_PARAMS = [
      'text_search',
      'first_name',
      'last_name',
      'dob',
      'ssn_serial',
      'personal_id',
    ].freeze

    # For now, the current user can only view their own search queries.
    # This could be expanded in the future to allow URL sharing, but that would require care, such as
    # avoiding returning search queries that include SSN to users who don't have permission to view SSN.
    scope :viewable_by, ->(user) { where(created_by: user) }

    def self.find_or_create_by_params(params, user:)
      norm = normalize_params(params)

      # Validate params first
      instance = new(params: norm)
      instance.validate_params
      return instance if instance.errors.any?

      fingerprint = generate_fingerprint(norm)

      # `upsert` then `find_by!` ensures the write path is atomic across workers,
      # compared to the Rails pattern of `find_or_create_by!`,
      # which can hit duplicate-key errors when two workers try to create the same row.
      upsert(
        { fingerprint: fingerprint, params: norm, created_by_id: user.id, data_source_id: user.hmis_data_source_id },
        unique_by: [:data_source_id, :created_by_id, :fingerprint],
        # If a row with this [data_source_id, created_by_id, fingerprint] already exists,
        # refresh `params` to match the incoming request. (A mismatch would be unexpected because fingerprint is derived from params.)
        on_duplicate: Arel.sql('params = EXCLUDED.params, updated_at = NOW()'),
      )

      find_by!(fingerprint: fingerprint, created_by_id: user.id, data_source_id: user.hmis_data_source_id)
    end

    # Canonical form for validation, fingerprinting, and storage so equivalent searches share one row.
    # Callers (GraphQL) pass a plain Hash from input coercion.
    def self.normalize_params(params)
      return {} if params.nil?

      hash = params.to_h.deep_stringify_keys

      hash.transform_values do |v|
        case v
        when Hash
          normalize_params(v)
        when Array
          normalize_array(v)
        when String
          v.strip
        else
          v
        end
      end.reject { |_, v| v.blank? }.sort.to_h
    end

    def self.normalize_array(arr)
      arr.map do |e|
        case e
        when Hash
          normalize_params(e)
        when String
          e.strip
        else
          e
        end
      end.reject(&:blank?).sort_by(&:to_json)
    end
  end
end
