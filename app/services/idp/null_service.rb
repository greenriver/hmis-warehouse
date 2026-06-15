###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Null object for IDPs that only authenticate and expose no manageable admin
  # API or for an unknown/blank connector. All management operations
  # raise; all capability predicates are false.
  class NullService < Service
    attr_reader :connector_id

    def initialize(connector_id = nil)
      @connector_id = connector_id
      super(config: {})
    end

    def create_user(**)
      raise ServiceError.new('User management not supported', idp_name: idp_name, operation: :create_user)
    end

    def update_user(**)
      raise ServiceError.new('Profile updates not supported', idp_name: idp_name, operation: :update_user)
    end

    def get_user(**)
      raise ServiceError.new('User lookup not supported', idp_name: idp_name, operation: :get_user)
    end

    def reactivate_user(**)
      raise ServiceError.new('User reactivation not supported', idp_name: idp_name, operation: :reactivate_user)
    end

    def idp_name
      connector_id&.humanize || 'Unknown IDP'
    end
  end
end
