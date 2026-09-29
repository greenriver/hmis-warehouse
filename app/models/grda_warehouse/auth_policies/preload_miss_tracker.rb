###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Counts single-id fallback lookups on a UserBaseContext, one Set of ids per kind. Passing the
# threshold means a caller checked a list of clients without calling
# policy_context.preload_client_dependencies first. Development and test raise so specs with a
# handful of rows catch it. Staging and production send one Sentry warning per kind and call site
# and the lookup still answers; staging shares the low threshold because manual QA there runs
# against small data sets.
class GrdaWarehouse::AuthPolicies::PreloadMissTracker
  THRESHOLD = Rails.env.production? ? 10 : 3

  # Frames between the caller's loop and this tracker. Skipping them makes the Sentry issue group
  # by the file that needs to call preload_client_dependencies.
  PLUMBING_PATHS = [
    'app/models/grda_warehouse/auth_policies/',
    'app/models/grda_warehouse/pii_provider.rb',
    'app/models/user.rb',
  ].freeze
  PLUMBING_METHODS = ['pii_provider', 'policy_for'].freeze

  class PreloadMissError < StandardError; end

  def initialize
    @missed_ids = Hash.new { |hash, kind| hash[kind] = Set.new }
    @reported_kinds = Set.new
  end

  def record(kind, id)
    ids = @missed_ids[kind]
    ids << id
    return if ids.size <= THRESHOLD || @reported_kinds.include?(kind)

    @reported_kinds << kind
    message = "#{kind} was looked up one client at a time for more than #{THRESHOLD} clients; " \
      'call policy_context.preload_client_dependencies(client_ids) before the loop'
    raise PreloadMissError, message if Rails.env.local?

    site = call_site
    Sentry.capture_message(
      message,
      level: :warning,
      backtrace: caller,
      fingerprint: ['preload-miss', kind.to_s, site],
      tags: { preload_miss_call_site: site },
      extra: { kind: kind, threshold: THRESHOLD },
    )
  end

  # Repo-relative path of the first app or driver frame outside the policy plumbing. The path
  # alone, without line or method, keeps the fingerprint stable across unrelated edits and
  # compiled-template method names.
  private def call_site
    root = "#{Rails.root}/"
    caller_locations.each do |location|
      path = location.absolute_path.to_s.delete_prefix(root)
      next unless path.start_with?('app/', 'drivers/')
      next if path.start_with?(*PLUMBING_PATHS) || location.base_label.in?(PLUMBING_METHODS)

      return path
    end
    'unknown'
  end
end
