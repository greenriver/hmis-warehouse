###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::AuthPolicies::ContextLoaders
  class ClientRoiLoader
    def initialize(user)
      # { client_id => bool }
      @cache = {}
      @today = Date.current
      @user_coc_codes = user.coc_codes
    end

    def get(client_id)
      return unless client_id

      preload([client_id]) unless @cache.key?(client_id)
      @cache[client_id]
    end

    def preload(client_ids)
      return if client_ids.empty?

      new_client_ids = client_ids.uniq - @cache.keys
      return if new_client_ids.empty?

      # Default to false so we cache a result for clients without roi records
      new_client_ids.each { |id| @cache[id] = false }

      scope = GrdaWarehouse::ClientRoiAuthorization.active(@today).where(destination_client_id: new_client_ids)
      scope.order(:id).group_by(&:destination_client_id).each do |id, auths|
        @cache[id] = auths.any? { |a| a.matches_coc_codes?(@user_coc_codes) }
      end
    end
  end
end
