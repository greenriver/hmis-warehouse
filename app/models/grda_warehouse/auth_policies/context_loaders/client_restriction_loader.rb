###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::AuthPolicies::ContextLoaders
  class ClientRestrictionLoader
    def initialize
      @restricted_client_ids = Set.new
      @loaded_client_ids = Set.new
    end

    def restricted?(destination_client_id)
      return false unless destination_client_id

      preload([destination_client_id])
      @restricted_client_ids.include?(destination_client_id)
    end

    def preload(destination_client_ids)
      new_ids = destination_client_ids.compact.uniq.reject { |id| @loaded_client_ids.include?(id) }
      return if new_ids.empty?

      @loaded_client_ids.merge(new_ids)
      @restricted_client_ids.merge(GrdaWarehouse::Hud::Client.hmis_restricted_destination_client_ids(new_ids))
    end
  end
end
