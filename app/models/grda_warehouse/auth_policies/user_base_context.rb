###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse/warehouse-auth-policies.md

require 'memery'

class GrdaWarehouse::AuthPolicies::UserBaseContext
  include Memery
  attr_reader :user

  EMPTY_SET = Set.new.freeze

  def initialize(user)
    raise ArgumentError, 'must be a user' unless user.is_a?(User)

    @user = user
  end

  memoize def client_roi_loader
    GrdaWarehouse::AuthPolicies::ContextLoaders::ClientRoiLoader.new(@user, miss_tracker: preload_miss_tracker)
  end

  memoize def restricted_client_loader
    GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader.new(miss_tracker: preload_miss_tracker)
  end

  def client_restricted?(client_id)
    return false unless client_id # keep first: nil must never cost a query

    restricted_client_loader.restricted?(client_id)
  end

  # For callers that only need restriction redaction and have no other client-keyed lookups you can use preload_client_restrictions
  # Use preload_client_dependencies if the caller will check other client-keyed lookups.
  def preload_client_restrictions(client_ids)
    restricted_client_loader.preload(client_ids)
  end

  # Fragment-cache key part for PII that belongs to one client. Restriction applies to the whole
  # identity, so the client's own answer changes whenever a restriction or merge affects it.
  def client_restriction_cache_token(client_id)
    "#{client_restricted?(client_id)}-#{latest_retention_run_at&.to_i}"
  end

  # Retention marks only change inside a ClientRetentionJob run, so the latest completed run
  # stands in for the marks table in fragment cache keys.
  memoize def latest_retention_run_at
    GrdaWarehouse::ClientRetentionRun.maximum(:completed_at)
  end

  # Warms every client-keyed lookup a client policy or PII check reads, for a list of clients.
  # Takes source or destination ids and widens them to each whole warehouse identity (the
  # destination and all of its sources): policies check source clients, while restriction and ROI
  # checks are often made by destination id. Ids already preloaded on this context are skipped.
  # @param client_ids [Enumerable<Integer, nil>]
  def preload_client_dependencies(client_ids)
    requested = client_ids.to_a.compact.uniq.reject { |id| preloaded_client_ids.include?(id) }
    return if requested.empty?

    links = GrdaWarehouse::HiddenClients.identity_links(requested)
    ids = (requested + links.flatten).uniq
    restricted_client_loader.preload(ids, links: links)
    client_roi_loader.preload(links.map(&:last).uniq)
    preload_client_grants(ids)
    preloaded_client_ids.merge(ids)
  end

  # For policies that resolve one client at a time. Free when a caller already preloaded the
  # client's identity; otherwise preloads it and counts a :destination_clients miss.
  def preload_client(client_id)
    return if client_id.nil? || preloaded_client_ids.include?(client_id)

    preload_miss_tracker.record(:destination_clients, client_id)
    preload_client_dependencies([client_id])
  end

  memoize private def preloaded_client_ids
    Set.new
  end

  memoize private def preload_miss_tracker
    GrdaWarehouse::AuthPolicies::PreloadMissTracker.new
  end
end
