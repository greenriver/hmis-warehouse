###
# Copyright Green River Data Group, Inc.
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

    def find_user_by_email(**)
      raise ServiceError.new('User lookup not supported', idp_name: idp_name, operation: :find_user_by_email)
    end

    def send_execute_actions_email(**)
      raise ServiceError.new('Account setup email not supported', idp_name: idp_name, operation: :send_execute_actions_email)
    end

    def reactivate_user(**)
      raise ServiceError.new('User reactivation not supported', idp_name: idp_name, operation: :reactivate_user)
    end

    def deactivate_user(**)
      raise ServiceError.new('User deactivation not supported', idp_name: idp_name, operation: :deactivate_user)
    end

    def set_required_action(**)
      raise ServiceError.new('Required actions not supported', idp_name: idp_name, operation: :set_required_action)
    end

    def idp_name
      connector_id&.humanize || 'Unknown IDP'
    end
  end
end
