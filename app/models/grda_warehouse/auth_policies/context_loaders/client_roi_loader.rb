###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::AuthPolicies::ContextLoaders
  class ClientRoiLoader
    def initialize(user, miss_tracker: nil)
      # { destination_client_id => bool }
      @cache = {}
      @today = Date.current
      @user_coc_codes = user.coc_codes
      @miss_tracker = miss_tracker
    end

    def get(client_id)
      return unless client_id

      unless @cache.key?(client_id)
        @miss_tracker&.call(:client_roi, client_id)
        preload([client_id])
      end
      @cache[client_id]
    end

    def preload(client_ids)
      return if client_ids.empty?

      new_client_ids = client_ids.uniq - @cache.keys
      return if new_client_ids.empty?

      new_client_ids.each { |id| @cache[id] = false }

      GrdaWarehouse::ClientRoiAuthorization.visible_in_cocs(@user_coc_codes, @today).
        where(destination_client_id: new_client_ids).
        pluck(:destination_client_id).
        each { |id| @cache[id] = true }
    end
  end
end
