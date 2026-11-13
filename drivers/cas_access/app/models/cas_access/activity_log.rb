###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasAccess
  class ActivityLog < CasBase
    self.table_name = :activity_logs
    belongs_to :user

    # `range` is a Date..Date; created_at is a UTC instant, so bare Date bounds would drop
    # evening (Eastern) activity on the last day.
    # A class method rather than a scope so it is also defined when the CAS database is absent and
    # CasBase is the non-ActiveRecord stub.
    def self.created_in_range(range:)
      where(created_at: range.begin.beginning_of_day..range.end.end_of_day)
    end

    # Same shape as ActivityLog.export_rows. Nil when the CAS database is not configured.
    def self.export_rows(user_id: nil, range: 1.years.ago..Time.current, limit: nil)
      return nil unless db_exists?

      columns = {
        user_id: 'CAS User ID',
        agency_name_column => 'Agency Name',
        path: 'Path',
        created_at: 'Access Time',
        session_hash: 'Session',
        ip_address: 'IP Address',
        referrer: 'Referrer',
      }
      scope = where(created_at: range).left_outer_joins(user: :agency)
      scope = scope.where(user_id: user_id) if user_id.present?
      scope = scope.limit(limit) if limit
      Enumerator.new do |rows|
        rows << columns.values
        scope.in_batches do |batch|
          scrub(pluck_to_hash(columns, batch)).each { |row| rows << row.values_at(*columns.keys) }
        end
      end
    end

    def self.agency_name_column
      CasAccess::Agency.arel_table[:name]
    end

    def self.scrub(data)
      data.map do |row|
        # Strip anything after the ?
        row[:path] = row[:path]&.gsub(/\?.*/, '')
        row[:referrer] = row[:referrer]&.gsub(/\?.*/, '')
        row[:created_at] = row[:created_at].to_fs(:db)
        row
      end
    end

    def self.pluck_to_hash(columns, scope, exclude: [])
      keys = columns.keys.excluding(exclude)
      scope.pluck(*keys).map do |row|
        Hash[keys.zip(row)]
      end
    end
  end
end
