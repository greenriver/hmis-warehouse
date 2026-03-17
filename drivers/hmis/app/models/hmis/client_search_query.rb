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

      fingerprint = generate_fingerprint(params, user)
      upsert(
        { fingerprint: fingerprint, params: params, created_by_id: user.id },
        unique_by: :fingerprint,
        # finding a duplicate by fingerprint where the params and created_by_id differ is unexpected,
        # because the fingerprint is generated based on params and created_by_id.
        on_duplicate: Arel.sql('params = EXCLUDED.params, created_by_id = EXCLUDED.created_by_id'),
      )

      find_by!(fingerprint: fingerprint)
    end

    def self.generate_fingerprint(params, user)
      Digest::SHA256.hexdigest({ "params": params, "user": user }.to_json)
    end
  end
end
