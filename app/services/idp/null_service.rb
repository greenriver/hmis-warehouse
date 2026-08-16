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
      raise ServiceError.new('User management not supported', idp_name: idp_name, operation: :create_user, transient: false)
    end

    def update_user(**)
      raise ServiceError.new('Profile updates not supported', idp_name: idp_name, operation: :update_user, transient: false)
    end

    def get_user(**)
      raise ServiceError.new('User lookup not supported', idp_name: idp_name, operation: :get_user, transient: false)
    end

    def find_user_by_email(**)
      raise ServiceError.new('User lookup not supported', idp_name: idp_name, operation: :find_user_by_email, transient: false)
    end

    def send_execute_actions_email(**)
      raise ServiceError.new('Account setup email not supported', idp_name: idp_name, operation: :send_execute_actions_email, transient: false)
    end

    def reactivate_user(**)
      raise ServiceError.new('User reactivation not supported', idp_name: idp_name, operation: :reactivate_user, transient: false)
    end

    def deactivate_user(**)
      raise ServiceError.new('User deactivation not supported', idp_name: idp_name, operation: :deactivate_user, transient: false)
    end

    def set_required_action(**)
      raise ServiceError.new('Required actions not supported', idp_name: idp_name, operation: :set_required_action, transient: false)
    end

    def logout_user_sessions(**)
      raise ServiceError.new('Session logout not supported', idp_name: idp_name, operation: :logout_user_sessions, transient: false)
    end

    def idp_name
      connector_id&.humanize || 'Unknown IDP'
    end

    def profile_source
      :none
    end
  end
end
