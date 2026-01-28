###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Loads project IDs for client enrollments in bulk
module Hmis::AuthPolicies::ContextLoaders
  class ClientProjectLoader
    include ArelHelper

    def initialize
      # { client_id => [project_id, ...] }
      @cache = {}
    end

    # Get project IDs for a single client
    def get(client_id)
      preload([client_id]) unless @cache.key?(client_id)
      @cache[client_id] || Set.new
    end

    def cached_project_ids
      @cache.values.flat_map(&:to_a).uniq
    end

    # Preload project IDs for multiple clients at once
    def preload(client_ids)
      return if client_ids.empty?

      new_client_ids = client_ids.uniq - @cache.keys
      return if new_client_ids.empty?

      # Ensure we cache empty sets for clients with no enrollments
      new_client_ids.each { |id| @cache[id] ||= Set.new }

      # Load all enrollments for these clients and group by client_id
      enrollments = Hmis::Hud::Enrollment.joins(:client).
        merge(Hmis::Hud::Client.where(id: new_client_ids)).
        pluck(c_t[:id], e_t[:project_pk])

      enrollments.each do |client_id, project_id|
        @cache[client_id] ||= Set.new
        @cache[client_id] << project_id
      end
    end
  end
end
