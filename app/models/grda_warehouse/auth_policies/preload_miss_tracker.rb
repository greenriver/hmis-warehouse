###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Counts single-id fallback lookups on a UserBaseContext, one Set of ids per kind. Passing the
# threshold means a caller checked a list of clients without calling
# policy_context.preload_client_dependencies first. Development and test raise at a low threshold
# so specs with a handful of rows catch it; elsewhere one Sentry warning per kind is sent at a
# higher threshold and the lookup still answers.
class GrdaWarehouse::AuthPolicies::PreloadMissTracker
  THRESHOLD = Rails.env.local? ? 3 : 10

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

    Sentry.capture_message(message, level: :warning, extra: { kind: kind, threshold: THRESHOLD })
  end
end
