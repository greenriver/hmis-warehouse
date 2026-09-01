###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::AuthPolicies::ContextLoaders
  class RestrictedClientLoader
    include ArelHelper

    RESTRICTED_POPULATION_WARN_THRESHOLD = 50_000

    # Restriction is expected to apply to a small fraction of clients (see
    # docs/features/hmis/hmis-restricted-records.md), so we load the whole set once rather than
    # batching per page. Everything sharing a destination identity with a restricted client is
    # restricted, so a source id, a destination id, and an unmerged source id all answer correctly.
    #
    # One hop only: a row that is both a source and a destination (bad data, see
    # GrdaWarehouse::Hud::Client#destination?) does not pull in its grandparent. That matches the
    # behavior this replaced -- don't "fix" it without deciding what the right answer is.
    def restricted_client_ids
      @restricted_client_ids ||= load_restricted_client_ids
    end

    def restricted?(client_id)
      return false unless client_id # keep first: see the laziness note below

      restricted_client_ids.include?(client_id)
    end

    # Changes whenever the restricted population changes, so fragment caches holding redacted PII
    # are invalidated by a restriction that touches none of the records already in their key.
    # Digests the full set, not just the directly-restricted ids, so a merge that changes
    # membership busts it too.
    def cache_token
      @cache_token ||= Digest::MD5.hexdigest(restricted_client_ids.to_a.sort.join(','))
    end

    private def load_restricted_client_ids
      ids = Hmis::RestrictedRecord.for_clients.pluck(:restrictable_id)
      return Set.new if ids.empty?

      warn_if_unexpectedly_large(ids)
      destination_ids = merge_links.where(wc_t[:source_id].in(ids).or(wc_t[:destination_id].in(ids))).
        pluck(:destination_id)
      sibling_source_ids = merge_links.where(destination_id: destination_ids).pluck(:source_id)
      (ids + destination_ids + sibling_source_ids).to_set
    end

    # WarehouseClient has acts_as_paranoid commented out but ClientCleanup
    # marks rows whose destination was emptied with a deleted_at timestamp.
    # This ignores marked rows.
    private def merge_links
      GrdaWarehouse::WarehouseClient.where(deleted_at: nil)
    end

    private def warn_if_unexpectedly_large(ids)
      return if ids.size <= RESTRICTED_POPULATION_WARN_THRESHOLD

      Sentry.capture_message(
        'RestrictedClientLoader: restricted client population exceeds the threshold this loader assumes',
        level: :warning,
        extra: { count: ids.size, threshold: RESTRICTED_POPULATION_WARN_THRESHOLD },
      )
    end
  end
end
