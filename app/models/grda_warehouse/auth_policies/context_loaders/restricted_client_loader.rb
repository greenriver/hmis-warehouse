###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::AuthPolicies::ContextLoaders
  # Answers whether a client is hidden (HMIS-restricted or retention-inactive, see
  # GrdaWarehouse::HiddenClients). Both populations can be large, so neither is loaded whole:
  # #preload resolves a page of ids in a fixed number of queries and memoizes each answer.
  class RestrictedClientLoader
    # @param miss_tracker [GrdaWarehouse::AuthPolicies::PreloadMissTracker, nil]
    def initialize(miss_tracker: nil)
      @miss_tracker = miss_tracker
      @hidden = {}
    end

    def restricted?(client_id)
      return false unless client_id # keep first: callers rely on nil costing no query
      return @hidden[client_id] if @hidden.key?(client_id)

      @miss_tracker&.call(:client_restrictions, client_id)
      preload([client_id])
      @hidden[client_id]
    end

    # @param identity_links [Array<Array(Integer, Integer)>, nil] identity links covering +client_ids+, when the caller has them
    def preload(client_ids, identity_links: nil)
      missing = client_ids.compact.uniq.reject { |id| @hidden.key?(id) }
      return if missing.empty?

      found = GrdaWarehouse::HiddenClients.restricted_subset(missing, identity_links: identity_links) | GrdaWarehouse::HiddenClients.inactive_subset(missing)
      missing.each { |id| @hidden[id] = found.include?(id) }
    end
  end
end
