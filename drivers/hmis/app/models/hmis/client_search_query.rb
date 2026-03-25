# frozen_string_literal: true

module Hmis
  class ClientSearchQuery < GrdaWarehouseBase
    include ClientSearchQueryShared
    belongs_to :created_by, class_name: 'Hmis::User'

    ALLOWED_PARAMS = [
      'text_search',
      'first_name',
      'last_name',
      'dob',
      'ssn_serial',
      'personal_id',
      # The following search types are not currently used in the frontend,
      # but supported by HmisSchema::ClientSearchInput and tested in rspec, so no harm in keeping them here
      'warehouse_id',
      'projects',
      'organizations',
    ].freeze

    # For now, the current user can only view their own search queries.
    # This could be expanded in the future to allow URL sharing, but that would require care, such as
    # avoiding returning search queries that include SSN to users who don't have permission to view SSN.
    scope :viewable_by, ->(user) { where(created_by: user) }

    def self.find_or_create_by_params(params, user:)
      # Validate params first
      instance = new(params: params)
      instance.validate_params
      return instance if instance.errors.any?

      fingerprint = generate_fingerprint(params)

      # `upsert` then `find_by!` ensures the write path is atomic across workers,
      # compared to the Rails pattern of `find_or_create_by!`,
      # which can hit duplicate-key errors when two workers try to create the same row.
      upsert(
        { fingerprint: fingerprint, params: params, created_by_id: user.id, data_source_id: user.hmis_data_source_id },
        unique_by: [:data_source_id, :created_by_id, :fingerprint],
        # If a row with this [data_source_id, created_by_id, fingerprint] already exists,
        # refresh `params` to match the incoming request. (A mismatch would be unexpected because fingerprint is derived from params.)
        on_duplicate: Arel.sql('params = EXCLUDED.params'),
      )

      find_by!(fingerprint: fingerprint, created_by_id: user.id, data_source_id: user.hmis_data_source_id)
    end
  end
end
