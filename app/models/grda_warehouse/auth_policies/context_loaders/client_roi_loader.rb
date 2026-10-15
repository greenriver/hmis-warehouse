###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::AuthPolicies::ContextLoaders
  class ClientRoiLoader
    def initialize(user, miss_tracker: nil)
      # @cache format:
      # { destination_client_id => visible ROI status, or nil when none is visible }.
      # client_roi_authorizations is unique on destination_client_id, so each id plucks at most one row.
      @cache = {}
      @today = Date.current
      @user_coc_codes = user.coc_codes
      @miss_tracker = miss_tracker
    end

    # @return [Boolean] a visible ROI row exists for the destination
    def get(client_id)
      !status(client_id).nil?
    end

    # @return [Boolean] the visible ROI row is a full release; the dashboard gate needs this
    def full_release?(client_id)
      status(client_id) == GrdaWarehouse::ClientRoiAuthorization::FULL_STATUS
    end

    def preload(client_ids)
      return if client_ids.empty?

      new_client_ids = client_ids.uniq - @cache.keys
      return if new_client_ids.empty?

      new_client_ids.each { |id| @cache[id] = nil }

      GrdaWarehouse::ClientRoiAuthorization.
        visible_in_cocs(@user_coc_codes, @today).
        with_consenting_source.
        where(destination_client_id: new_client_ids).
        pluck(:destination_client_id, :status).
        each { |id, status| @cache[id] = status }
    end

    private def status(client_id)
      return unless client_id

      unless @cache.key?(client_id)
        @miss_tracker&.call(:client_roi, client_id)
        preload([client_id])
      end
      @cache[client_id]
    end
  end
end
