###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Counts SQL statements issued inside the block, ignoring schema, cache hits, and
# transaction bookkeeping, so two blocks can be compared for N+1 growth.
module QueryCounting
  IGNORED_NAMES = ['SCHEMA', 'CACHE', 'TRANSACTION'].freeze
  IGNORED_SQL = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i

  def count_database_queries
    count = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*_, payload|
      next if payload[:cached]
      next if IGNORED_NAMES.include?(payload[:name])
      next if payload[:sql].match?(IGNORED_SQL)

      count += 1
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end

RSpec.configure do |config|
  config.include QueryCounting
end
